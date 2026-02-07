import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:bantuin/Logic/services/pelanggan_service.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const CustomerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  final CustomerService _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          "Detail Pesanan",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _customerService.getOrderDetailStream(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Pesanan tidak ditemukan."));
          }

          var orderData = snapshot.data!.data() as Map<String, dynamic>;
          String status = orderData['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBadge(status),
                const SizedBox(height: 20),
                Text("Order ID: ${widget.orderId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 32),
                
                // --- TAMPILAN INFORMASI LAYANAN (SAMA SEPERTI ASLI) ---
                _buildInfoRow("Layanan", orderData['serviceName'] ?? "-"),
                _buildInfoRow("Kategori", orderData['category'] ?? "-"),
                _buildInfoRow("Tanggal", _formatDate(orderData['createdAt'])),
                const Divider(height: 32),
                
                _buildInfoRow("Alamat", orderData['address'] ?? "-"),
                const SizedBox(height: 10),
                _buildInfoRow("Catatan", orderData['notes'] ?? "Tidak ada catatan"),
                
                const SizedBox(height: 40),
                
                // --- TOMBOL BATALKAN (HANYA MUNCUL JIKA STATUS PENDING) ---
                if (status == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showCancelConfirmation(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        side: BorderSide(color: Colors.red.shade100),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Batalkan Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String label = "Menunggu Konfirmasi";
    
    if (status == 'accepted') { color = Colors.green; label = "Diterima"; }
    else if (status == 'cancelled') { color = Colors.red; label = "Dibatalkan"; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "-";
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Batalkan Pesanan?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kembali")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _customerService.cancelOrder(widget.orderId);
              if (mounted) Navigator.pop(context);
            }, 
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}