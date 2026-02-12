import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'package:google_fonts/google_fonts.dart'; 

class NotificationProviderScreen extends StatelessWidget {
  final String orderId;

  const NotificationProviderScreen({Key? key, required this.orderId}) : super(key: key);

 
  String _timeAgo(DateTime dateTime) {
   
    final nowUtc = DateTime.now().toUtc();
    final dateTimeUtc = dateTime.toUtc(); // Pastikan dateTime juga dikonversi ke UTC jika belum

    // Tambahkan offset WIB ke waktu sekarang jika dateTime dari server adalah UTC
    // Jika dateTime dari server sudah dalam WIB (misalnya disimpan dengan offset), maka baris ini tidak perlu.
    // final nowInWIB = nowUtc.add(const Duration(hours: 7));

    

    final now = DateTime.now(); // Waktu lokal perangkat
    final difference = now.difference(dateTime); // dateTime diasumsikan sudah dalam zona waktu yang benar atau dikonversi

    if (difference.inSeconds < 60) return 'Baru saja';
    if (difference.inMinutes < 60) return '${difference.inMinutes} menit yang lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam yang lalu';
    if (difference.inDays == 1) return 'Kemarin';
    return '${difference.inDays} hari yang lalu';
  }


  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width; // Tidak terlalu diperlukan jika Card sudah di-center

    // Sebaiknya, jika ini adalah dialog, Scaffold bisa dihilangkan dan langsung return Dialog
    // Namun, karena ada WillPopScope, kita pertahankan strukturnya
    // dan pastikan Scaffold memiliki background transparan agar Card terlihat sebagai dialog.
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.4), // Latar belakang semi-transparan untuk efek dialog
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView( // Untuk menghindari overflow jika konten terlalu panjang
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Padding luar untuk Card
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
                builder: (context, orderSnapshot) {
                  if (orderSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
                    return _buildErrorCard(context,"Pesanan tidak ditemukan.");
                  }
                  if (orderSnapshot.hasError) {
                    return _buildErrorCard(context, "Gagal memuat pesanan.");
                  }

                  var order = orderSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  var details = order['details'] as Map<String, dynamic>? ?? {}; 
                  String customerId = order['customerId'] ?? '';
                  String serviceType = details['service'] ?? order['service'] ?? 'Layanan Tidak Diketahui'; // Ambil dari order jika tidak ada di details
                  DateTime createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  String timeAgo = _timeAgo(createdAt);

                  if (customerId.isEmpty) {
                     return _buildErrorCard(context, "Data pelanggan tidak valid.");
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('customers').doc(customerId).get(),
                    builder: (context, customerSnapshot) {
                      if (customerSnapshot.connectionState == ConnectionState.waiting && !customerSnapshot.hasData) {
                         // Tampilkan card dengan loading state untuk info customer
                        return _buildNotificationCardContent(
                          context: context,
                          customerName: "Memuat nama...",
                          customerPhotoUrl: null, // Atau URL placeholder jika ada
                          isLoadingCustomer: true,
                          serviceType: serviceType,
                          timeAgo: timeAgo,
                          onAccept: () {  },
                          onReject: () {  },
                        );
                      }
                      
                      String customerName = 'Pelanggan';
                      String? customerPhotoUrl; 

                      if (customerSnapshot.hasData && customerSnapshot.data!.exists) {
                        var customerData = customerSnapshot.data!.data() as Map<String, dynamic>;
                        customerName = customerData['nama'] ?? 'Pelanggan Yth.';
                        customerPhotoUrl = customerData['photoUrl'] as String?; // Ambil URL foto jika ada
                      } else if (customerSnapshot.hasError) {
                        customerName = 'Gagal memuat nama';
                      }


                      // --- Fungsionalitas Tombol Tetap Sama ---
                      VoidCallback acceptOrder = () {
                        FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                          'status': 'accepted',
                          'providerId': FirebaseAuth.instance.currentUser?.uid,
                        });
                        Navigator.pop(context); // Tutup dialog
                        // Navigasi ke halaman manajemen order provider jika ada
                        // Navigator.pushReplacementNamed(context, '/order_management_provider');
                         try {
                            Navigator.pushReplacementNamed(context, '/order_management');
                         } catch (e) {
                            print("Gagal navigasi ke /order_management: $e. Mungkin route belum didefinisikan.");
                            
                         }
                      };

                      VoidCallback rejectOrder = () {
                        FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                          'status': 'rejected',
                          
                          'rejectedByProviderId': FirebaseAuth.instance.currentUser?.uid,
                        });
                        Navigator.pop(context); 
                      };
                      // --- Akhir Fungsionalitas Tombol ---

                      return _buildNotificationCardContent(
                        context: context,
                        customerName: customerName,
                        customerPhotoUrl: customerPhotoUrl,
                        isLoadingCustomer: customerSnapshot.connectionState == ConnectionState.waiting,
                        serviceType: serviceType,
                        timeAgo: timeAgo,
                        onAccept: acceptOrder,
                        onReject: rejectOrder,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String errorMessage) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildNotificationCardContent({
    required BuildContext context,
    required String customerName,
    required String? customerPhotoUrl,
    required bool isLoadingCustomer,
    required String serviceType,
    required String timeAgo,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    return Card(
      elevation: 8.0, // Beri sedikit shadow
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // Sudut lebih bulat
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Agar card menyesuaikan konten
          crossAxisAlignment: CrossAxisAlignment.stretch, // Agar tombol memenuhi lebar
          children: [
            // Header: Avatar dan Nama Customer
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: customerPhotoUrl != null && customerPhotoUrl.isNotEmpty
                      ? NetworkImage(customerPhotoUrl)
                      : null,
                  child: customerPhotoUrl == null || customerPhotoUrl.isEmpty
                      ? Icon(Icons.person, size: 30, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLoadingCustomer)
                        Text("Memuat pelanggan...", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey))
                      else
                        Text(
                          customerName,
                          style: GoogleFonts.poppins(
                            fontSize: 18, // Sedikit lebih besar
                            fontWeight: FontWeight.w600, // Bold
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        'Mencari teknisi di dekat Anda', // Pesan disesuaikan
                        style: GoogleFonts.poppins(
                          fontSize: 14, // Ukuran standar
                          fontWeight: FontWeight.normal,
                          color: Colors.black54, // Warna lebih lembut
                        ),
                      ),
                    ],
                  ),
                ),
                Text( // Waktu
                  timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600, // Warna lembut
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Spasi antar bagian

            // Detail Pesanan
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50, // Warna latar yang lembut untuk detail
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.build_circle_outlined, color: Theme.of(context).primaryColor, size: 22), // Ikon yang relevan
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Layanan: $serviceType',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // Spasi sebelum tombol

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject, // Fungsionalitas tidak berubah
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300, // Warna tombol tolak
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Tolak',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept, // Fungsionalitas tidak berubah
                    style: ElevatedButton.styleFrom(
                      // Gunakan warna tema utama aplikasi Anda jika ada, atau warna yang lebih menonjol
                      backgroundColor: Theme.of(context).primaryColorDark, // Contoh: Color(0xFF192655)
                      foregroundColor: Colors.white,
                      elevation: 2, // Sedikit elevasi untuk tombol utama
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Terima',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}