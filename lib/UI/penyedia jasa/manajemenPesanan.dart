import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bantuin/Logic/services/penyediaJasa_service.dart';
import 'package:bantuin/UI/penyedia jasa/orderListItem.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});
  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final ProviderService _service = ProviderService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text("Kelola Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18)),
          backgroundColor: Colors.grey[100],
          elevation: 0,
          bottom: _buildTabBar(),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(_service.getCombinedOrdersStream(_uid), "Tidak ada pesanan baru"),
            _buildOrderList(_service.getCompletedOrdersStream(_uid), "Belum ada pesanan selesai"),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() { /* Gunakan desain TabBar asli Anda */ return const PreferredSize(preferredSize: Size.zero, child: SizedBox()); }

  Widget _buildOrderList(Stream stream, String emptyMsg) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data is List ? snapshot.data : (snapshot.data as QuerySnapshot?)?.docs;
        if (docs == null || docs.isEmpty) return Center(child: Text(emptyMsg));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: docs.length,
          itemBuilder: (context, index) => ProviderOrderListItem(orderDoc: docs[index]),
        );
      },
    );
  }
}