import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String chatRoomId, String senderId, String text) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('chats').doc(chatRoomId).set({
        'lastMessage': text,
        'lastSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [senderId, chatRoomId.split('_').firstWhere((id) => id != senderId, orElse: () => '')],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error sending message: $e');
      rethrow; 
    }
  }


  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(50) 
          .snapshots();
    } catch (e) {
      print('Error getting messages: $e');
      return const Stream.empty();
    }
  }
}