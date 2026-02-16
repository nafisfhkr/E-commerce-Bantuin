import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Komunikasi extends StatefulWidget {
  final String receiverUserId;

  const Komunikasi({Key? key, required this.receiverUserId}) : super(key: key);

  @override
  State<Komunikasi> createState() => _KomunikasiState();
}

class _KomunikasiState extends State<Komunikasi> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  final FirebaseFirestore _chatService = FirebaseFirestore.instance;
  late String chatRoomId;


  String receiverName = '';
  String receiverRole = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chatRoomId = generateChatRoomId(currentUser.uid, widget.receiverUserId);
    _fetchReceiverData();
  }

  void _fetchReceiverData() async {
    try {
      final userData =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverUserId)
              .get();

      if (userData.exists) {
        setState(() {
          receiverName = userData.data()?['nama'] ?? 'Nama User';

          var roleData = userData.data()?['role'];
          if (roleData != null && roleData is List && roleData.isNotEmpty) {
            receiverRole = roleData[0].toString();
          } else if (roleData != null && roleData is String) {
            receiverRole = roleData;
          } else {
            receiverRole = 'Status user';
          }

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching receiver data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String generateChatRoomId(String userId, String otherUserId) {
    if (userId.hashCode <= otherUserId.hashCode) {
      return '$userId\_$otherUserId';
    } else {
      return '$otherUserId\_$userId';
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String messageText = _messageController.text.trim();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
          'text': messageText,
          'senderId': currentUser.uid,
          'timestamp': Timestamp.now(),
        });

    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'lastMessage': messageText,
      'lastSenderId': currentUser.uid,
      'lastMessageTime': Timestamp.now(),
      'participants': [currentUser.uid, widget.receiverUserId],
    }, SetOptions(merge: true));

    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F0), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F1F0),
        elevation: 0,
        shadowColor: Colors.grey.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child:
                  isLoading
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            receiverName, 
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            receiverRole, 
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.blue, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: const Color.fromARGB(255, 244, 243, 243)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatRoomId)
                        .collection('messages')
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada pesan',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  var messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isMe = message['senderId'] == currentUser.uid;

                      return MessageBubble(text: message['text'], isMe: isMe);
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C3879),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const MessageBubble({Key? key, required this.text, required this.isMe})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? const Color(0xFF1C3879)
                        : const Color(0xFF1C3879), 
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}