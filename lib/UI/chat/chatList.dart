import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'komunikasi.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;
  String _searchQuery = '';

  void _startChat(String receiverUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Komunikasi(receiverUserId: receiverUserId),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        automaticallyImplyLeading: true,
        title: const Text(
          'Daftar Chat',
          style: TextStyle(
            color: Color(0xFF2B4C8C),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            70.0,
          ), 
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              10,
            ),
            child: Container(
              height: 50, 
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  suffixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error fetching users: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2B4C8C),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No users found in Firestore');
                  return const Center(
                    child: Text(
                      'Tidak ada pengguna',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                var users =
                    snapshot.data!.docs.where((doc) {
                      if (doc.id == currentUser.uid) return false;

                      final data = doc.data() as Map<String, dynamic>;
                      final nama = data['nama']?.toString().toLowerCase() ?? '';
                      final email =
                          data['email']?.toString().toLowerCase() ?? '';

                      return nama.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }).toList();

                if (users.isEmpty) {
                  print('No users match the search query: $_searchQuery');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pengguna tidak ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final QueryDocumentSnapshot<Object?> doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String displayName =
                        data['nama'] ?? data['email'] ?? 'Nama Tidak Diketahui';

                    bool isOnline = false;
                    var status = data['status'];
                    if (status is bool) {
                      isOnline = status;
                    } else if (status is String) {
                      isOnline =
                          status.toLowerCase() == 'online' ||
                          status.toLowerCase() == 'true';
                    }

                    final String initial =
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 1.0,
                        ),
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF2B4C8C),
                              backgroundImage:
                                  data.containsKey('profilePicUrl') &&
                                          data['profilePicUrl'] != null &&
                                          (data['profilePicUrl'] as String)
                                              .isNotEmpty
                                      ? NetworkImage(
                                        data['profilePicUrl'] as String,
                                      )
                                      : null,
                              child:
                                  data.containsKey('profilePicUrl') &&
                                          data['profilePicUrl'] != null &&
                                          (data['profilePicUrl'] as String)
                                              .isNotEmpty
                                      ? null
                                      : Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color:
                                      isOnline
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey[400],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  isOnline
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[600],
                            ),
                          ),
                        ),
                        onTap: () {
                          print('Starting chat with user ID: ${doc.id}');
                          _startChat(doc.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}