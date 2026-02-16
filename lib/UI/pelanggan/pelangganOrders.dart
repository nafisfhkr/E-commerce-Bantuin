import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 


import 'package:bantuin/Logic/services/pelanggan_service.dart';
import 'package:bantuin/UI/pelanggan/pelangganOrderDetail.dart';

class CustomerOrderHistoryScreen extends StatefulWidget {
  const CustomerOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CustomerOrderHistoryScreen> createState() => _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState extends State<CustomerOrderHistoryScreen> {
  final CustomerService _service = CustomerService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }


  String _formatTimestampToDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Tanggal tidak tersedia';
    try {
      return DateFormat('MMMM dd, yyyy', 'id_ID').format(timestamp.toDate());
    } catch (e) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    }
  }

  String _getImageAssetPath(Map<String, dynamic> details) {
    if (details.containsKey('itemImageUrl') && details['itemImageUrl'] != null && details['itemImageUrl'].toString().isNotEmpty) {
      return details['itemImageUrl'];
    }
    
    String category = details['category'] as String? ?? '';

    if (category == 'Kendaraan') {
      String type = (details['type'] as String? ?? '').toLowerCase();
      String categoryType = (details['categoryType'] as String? ?? '').toLowerCase();
      const Map<String, String> vehicleFileMap = {
        'sedan': 'sedan.png', 'family': 'family.png', 'pickup': 'bak.png', 'sport': 'sport.png',
        'matic': 'matic.png', 'bebek': 'bebek.png', 'cruiser': 'cruiser.png', 'trail': 'Trail.png',
      };
      if (type.isNotEmpty && categoryType.isNotEmpty) {
        String fileName = vehicleFileMap[categoryType] ?? '$categoryType.png';
        return 'assets/images/vehicles/$type/$fileName';
      }
    }

    if (category == 'Elektronik') {
      String electronicType = details['electronicType'] as String? ?? '';
      String modelOrServiceKey = (details['electronicModel'] as String? ?? details['service'] as String? ?? '').toLowerCase();
      const Map<String, String> folderMap = {'office': 'kantor', 'household': 'rumahtangga', 'service': 'layanan'};
      const Map<String, String> fileMap = {
        'komputer': 'komputer dan aksesoris.png', 'audio': 'audio dan visual.png', 'hp': 'hp dan aksesoris.png',
        'pendingin_ruangan': 'pendingin.png', 'pendingin': 'pendingin.png', 'pembersih': 'pembersih.png', 'dapur': 'dapur.png',
        'perawatan': 'perawatan.png', 'instalasi': 'instalasi.png', 'perbaikan_mesin': 'perbaikan mesin.png', 'perbaikan_layar': 'perbaikan layar.png',
      };
      String folderName = folderMap[electronicType] ?? 'layanan';
      String fileName = fileMap[modelOrServiceKey] ?? 'lain-lain.png';
      return 'assets/images/elektronik/$folderName/$fileName';
    }
    return 'assets/images/elektronik/layanan/lain-lain.png';
  }

  Widget _buildOrdersList() {
    if (_currentUser == null) {
      return Center(child: Text("Silakan login untuk melihat riwayat.", style: GoogleFonts.poppins()));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _service.getOrderHistoryStream(_currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF192F65)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("Tidak ada riwayat pesanan.", style: GoogleFonts.poppins(color: Colors.grey[600])),
              ],
            ),
          );
        }

        var orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var orderData = orders[index].data() as Map<String, dynamic>;
            String orderId = orders[index].id;
            String status = orderData['status'] ?? 'N/A';
            Timestamp? createdAt = orderData['createdAt'] as Timestamp?;
            Map<String, dynamic> details = orderData['details'] as Map<String, dynamic>? ?? {};

            String serviceType = details['service'] as String? ?? '';
            String displayedCategory = details['type'] ?? details['vehicleType'] ?? details['electronicType'] ?? 'Lain-lain';
            String displayedType = details['categoryType'] ?? details['vehicleModel'] ?? details['electronicModel'] ?? '';

            String fullCategoryAndType = displayedType.isNotEmpty 
                ? '${_capitalizeEachWord(displayedCategory)} . ${_capitalizeEachWord(displayedType)}'
                : _capitalizeEachWord(displayedCategory);

            num subtotal = orderData['subtotal'] as num? ?? 0;
            num serviceFee = orderData['serviceFee'] as num? ?? 0;
            double totalPrice = (orderData['finalAmount'] as num?)?.toDouble() ?? (subtotal + serviceFee).toDouble();

            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerOrderDetailScreen(orderId: orderId))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          _buildImageThumbnail(details),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(_capitalizeEachWord(serviceType), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600))),
                                    Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0).format(totalPrice), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(fullCategoryAndType, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(status),
                          Text(_formatTimestampToDate(createdAt), style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> details) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(_getImageAssetPath(details), fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.build, color: Colors.grey[400], size: 24)),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color txtColor;
    String label;

    switch (status.toLowerCase()) {
      case 'completed': bgColor = Colors.green.shade50; txtColor = Colors.green.shade700; label = 'Selesai'; break;
      case 'pending': bgColor = Colors.orange.shade50; txtColor = Colors.orange.shade700; label = 'Menunggu'; break;
      case 'accepted': bgColor = Colors.blue.shade50; txtColor = Colors.blue.shade700; label = 'Diterima'; break;
      case 'cancelled': bgColor = Colors.red.shade50; txtColor = Colors.red.shade700; label = 'Dibatalkan'; break;
      default: bgColor = Colors.grey.shade100; txtColor = Colors.grey.shade700; label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: txtColor)),
    );
  }

  String _capitalizeEachWord(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 16, 16),
            child: Text("Riwayat Pesanan", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
          ),
          Expanded(child: _buildOrdersList()),
        ],
      ),
    );
  }
}