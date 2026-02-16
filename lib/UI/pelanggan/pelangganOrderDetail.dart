import 'package:bantuin/UI/maps/peta_driver.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const CustomerOrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _CustomerOrderDetailScreenState createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {

  Future<void> _cancelOrder() async {
    bool? confirmCancel = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Pesanan?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin membatalkan pesanan ini?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Tidak')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Ya, Batalkan', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmCancel == true) { 
      try {
        await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({'status': 'cancelled'});
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dibatalkan.'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membatalkan pesanan: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return 'N/A';
    if (text == 'work_done') return 'Pekerjaan Selesai';
    return text[0].toUpperCase() + text.substring(1);
  }
  
  String _getStatusImage(String status) {
    switch (status) {
      case 'pending': return 'assets/images/status_pending.png';
      case 'accepted':
      case 'processing': return 'assets/images/status_processing.png';
      case 'work_done': return 'assets/images/status_work_done.png';
      case 'completed': return 'assets/images/status_completed.png';
      case 'rejected':
      case 'cancelled': return 'assets/images/status_rejected.png';
      default: return 'assets/images/status_default.png';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.blueGrey;
      case 'accepted': case 'processing': return const Color(0xFFF8BD00);
      case 'work_done': return const Color(0xFF192F65);
      case 'completed': return const Color(0xFF4CAF50);
      case 'rejected': case 'cancelled': return const Color(0xFFD32F2F);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F1F0),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF1F1F0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Color(0xFF192F65)));
          if (!snapshot.hasData || !snapshot.data!.exists) return Center(child: Text("Pesanan tidak ditemukan.", style: GoogleFonts.poppins()));

          var orderData = snapshot.data!.data() as Map<String, dynamic>;
          String status = orderData['status'] ?? 'N/A';
          String? providerId = orderData['providerId'] as String?;
          
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(10.0),
                  children: [
                    _buildStatusHeader(status, orderData),
                    const SizedBox(height: 5),
                    _buildOrderInfoCard(orderData),
                    SizedBox(height: 5),
                    _buildServiceItemCard(orderData),
                    SizedBox(height: 5),
                    if (providerId != null && providerId.isNotEmpty)
                      _buildProviderInfoCard(providerId),
                    SizedBox(height: 5),
                    _buildPaymentInfoCard(orderData),
                    SizedBox(height: 20),
                    _buildActionButtons(status, providerId, orderData),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStatusHeader(String status, Map<String, dynamic> orderData) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12.0),
        image: DecorationImage(
          image: AssetImage(_getStatusImage(status)),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            print('Error loading status image: $exception');
          },
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _capitalizeFirstLetter(status),
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: Offset(1, 1))
                  ]),
            ),
            const SizedBox(height: 1),
            Text(
              _formatTimestamp(orderData['createdAt']),
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  shadows: [
                    Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 2,
                        offset: Offset(1, 1))
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(Map<String, dynamic> orderData) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Pesanan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildInfoRow('ID Pesanan', widget.orderId),
            const SizedBox(height: 8),
            _buildInfoRow('Waktu Pesanan', orderData['createdAt'] != null && orderData['providerId'] != null ? '${DateTime.now().difference(orderData['createdAt'].toDate()).inMinutes} Menit' : 'Belum diterima'),
            const SizedBox(height: 8),
            _buildInfoRow('Tanggal Pesanan', _formatTimestamp(orderData['createdAt'])),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItemCard(Map<String, dynamic> details) {
  String displayTitle;
  String displaySubtitle;
  String imagePath;
  IconData fallbackIcon;
  
  String _capitalizeEachWord(String? text) {
  if (text == null || text.isEmpty) return '';
  return text.replaceAll('_', ' ').split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

 
  if (details.containsKey('type') || details.containsKey('vehicleType')) {
    displayTitle = _capitalizeEachWord(details['service'] as String? ?? 'Servis Kendaraan');
    String itemType = _capitalizeEachWord(details['type'] as String? ?? 'Kendaraan');
    String categoryType = _capitalizeEachWord(details['categoryType'] as String? ?? '');
    displaySubtitle = '$itemType • $categoryType';

    imagePath = details['itemImageUrl'] as String? ??
        'assets/images/vehicles/${(details['type'] as String? ?? '').toLowerCase()}/${(details['categoryType'] as String? ?? '').toLowerCase()}.png';
    fallbackIcon = (details['type'] as String? ?? '').toLowerCase() == 'mobil'
        ? Icons.directions_car
        : Icons.motorcycle;
  }
  else {
    displayTitle = _capitalizeEachWord(details['service'] as String? ?? 'Servis Elektronik');

    const Map<String, String> typeLabels = {
      'office': 'Kantor',
      'household': 'Rumah Tangga',
      'service': 'Layanan'
    };
    const Map<String, String> modelLabels = {
      'perbaikan_mesin': 'Perbaikan Mesin',
      'perawatan': 'Perawatan',
      'komputer': 'Komputer & Aksesoris',
      'pendingin': 'Pendingin',
      'dapur': 'Dapur',
    };

    String typeKey = details['electronicType'] as String? ?? 'service';
    String modelKey =
        (details['electronicModel'] as String? ?? details['service'] as String? ?? '')
            .toLowerCase();

    String typeLabel = typeLabels[typeKey] ?? _capitalizeEachWord(typeKey);
    String modelLabel = modelLabels[modelKey] ?? _capitalizeEachWord(modelKey);

    displaySubtitle = '$typeLabel • $modelLabel';

    imagePath = details['itemImageUrl'] as String? ?? 'assets/images/elektronik/layanan/perbaikan mesin.png';
    fallbackIcon = Icons.electrical_services;
  }

  num finalAmount = 0;
  var rawFinalAmount = details['finalAmount'];

  if (rawFinalAmount != null) {
    if (rawFinalAmount is String) {
      finalAmount = num.tryParse(rawFinalAmount) ?? 0;
    } else if (rawFinalAmount is num) {
      finalAmount = rawFinalAmount;
    }
  }
   if (finalAmount == 0) {
      finalAmount = details['estimatedPriceMin'] ?? 35000;
  }

  return Card(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item Pesanan',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF192F65), width: 1.5)),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(fallbackIcon, color: Colors.grey[400], size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayTitle,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(displaySubtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                        NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp.',
                                decimalDigits: 0)
                            .format(finalAmount),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildProviderInfoCard(String providerId) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(providerId).get(),
          builder: (context, providerSnapshot) {
            if (!providerSnapshot.hasData)
              return const Center(child: Text("Memuat info teknisi..."));
            var providerData = providerSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            String providerName = providerData['nama'] ?? 'Teknisi';
            String? providerPhotoUrl = providerData['photo_url'];
            double rating = (providerData['rating'] ?? 4.5).toDouble();
            int reviewCount = providerData['review_count'] ?? 127;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Informasi Teknisi", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: providerPhotoUrl != null && providerPhotoUrl.isNotEmpty ? NetworkImage(providerPhotoUrl) : null,
                      backgroundColor: Colors.grey.shade300,
                      child: providerPhotoUrl == null || providerPhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.black54) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(providerName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text('$rating ($reviewCount Ulasan)', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Image.asset('assets/images/chat.png', width: 24, height: 24, color: const Color(0xFF192F65), errorBuilder: (c, e, s) => Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF192F65), size: 24)),
                      onPressed: () => Navigator.pushNamed(context, '/chat', arguments: {'receiverUserId': providerId}),
                    ),
                    IconButton(
                      icon: Image.asset('assets/images/telpon.png', width: 24, height: 24, color: const Color(0xFF192F65), errorBuilder: (c, e, s) => Icon(Icons.call_outlined, color: Color(0xFF192F65), size: 24)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(Map<String, dynamic> orderData) {
    num totalAmount = orderData['finalAmount'] ?? (orderData['subtotal'] ?? 0) + (orderData['serviceFee'] ?? 0);
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pembayaran', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 10),
            _buildPaymentRow('Metode', orderData['paymentMethod'] ?? 'Tunai'),
            SizedBox(height: 4),
            _buildPaymentRow('Subtotal', 'Rp. ${NumberFormat('#,###', 'id_ID').format(orderData['subtotal'] ?? 0)},00'),
            SizedBox(height: 4),
            _buildPaymentRow('Biaya Layanan', 'Rp. ${NumberFormat('#,###', 'id_ID').format(orderData['serviceFee'] ?? 0)},00'),
            SizedBox(height: 4),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Rp. ${NumberFormat('#,###', 'id_ID').format(totalAmount)},00', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF192F65))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700])),
          Text(value, style: GoogleFonts.poppins(fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }


  Widget _buildActionButtons(String status, String? providerId, Map<String, dynamic> orderData) {
    if (status == 'pending') {
      return ElevatedButton.icon(
        icon: Icon(Icons.cancel_outlined),
        label: Text("Batalkan Pesanan"),
        onPressed: _cancelOrder,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }

    if (status == 'accepted' || status == 'processing') {
      return ElevatedButton.icon(
        icon: Icon(Icons.map_outlined),
        label: Text("Lacak Teknisi"),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PetaGelap(orderId: widget.orderId))),
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF192F65), foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
    
    if (status == 'work_done') {
      final finalAmount = orderData['finalAmount'];
      if (finalAmount != null && finalAmount > 0) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return SizedBox.shrink();

        return ElevatedButton.icon(
          icon: Icon(Icons.payment),
          label: Text("Bayar Sekarang"),
          onPressed: () {   // 
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
          child: Text('Menunggu teknisi menetapkan harga akhir...', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.orange.shade800, fontWeight: FontWeight.w500)),
        );
      }
    }

    if (status == 'completed') {
    }
    
    return SizedBox.shrink();
  }
}