
import 'package:bantuin/UI/chat/komunikasi.dart';
import 'package:bantuin/UI/maps/peta_driver.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';



class ProviderOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const ProviderOrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ProviderOrderDetailScreen> createState() => _ProviderOrderDetailScreenState();
}

class _ProviderOrderDetailScreenState extends State<ProviderOrderDetailScreen> {
  final TextEditingController _finalAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSavingPrice = false;
  bool _isMarkingWorkDone = false;

  // --- LOGIKA ASLI (TIDAK BERUBAH) ---

  Future<void> _markWorkAsDone() async {
    setState(() => _isMarkingWorkDone = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'work_done', 
        'workDoneAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Pekerjaan ditandai selesai. Silakan tetapkan harga."),
          backgroundColor: Colors.blue
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isMarkingWorkDone = false);
    }
  }

  Future<void> _setFinalPrice() async {
    if (_formKey.currentState?.validate() != true) return;
    final priceText = _finalAmountController.text.replaceAll('.', '');
    final price = num.tryParse(priceText);
    
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Format harga tidak valid.")));
      return;
    }

    setState(() => _isSavingPrice = true);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'finalAmount': price, 
        'paymentStatus': 'unpaid', 
        'priceSetAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Harga akhir berhasil ditetapkan!"), 
          backgroundColor: Colors.green
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSavingPrice = false);
    }
  }

  // --- HELPER FUNCTIONS ---

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Data Waktu Tidak Ada';
    try {
      final date = timestamp.toDate();
      final dayName = DateFormat('EEEE', 'id_ID').format(date);
      final formattedDate = DateFormat('MMMM d, HH:mm', 'id_ID').format(date);
      return '$dayName, $formattedDate';
    } catch (e) {
      return 'Format Waktu Error';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Menunggu Diterima';
      case 'accepted':
      case 'processing': return 'Sedang Proses';
      case 'work_done': return 'Pekerjaan Selesai';
      case 'completed': return 'Selesai';
      case 'rejected': return 'Ditolak';
      default: return 'Status Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.blueGrey;
      case 'accepted':
      case 'processing': return const Color(0xFFF8BD00);
      case 'work_done': return const Color(0xFF192F65);
      case 'completed': return const Color(0xFF4CAF50);
      case 'rejected': return const Color(0xFFD32F2F);
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _finalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F0),
      appBar: AppBar(
        title: Text('Detail Pesanan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black87)),
        backgroundColor: const Color(0xFFF1F1F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var orderData = snapshot.data!.data() as Map<String, dynamic>;
          String status = orderData['status'] ?? 'N/A';
          String customerId = orderData['customerId'] ?? '';
          num? finalAmount = orderData['finalAmount'];
          String paymentStatus = orderData['paymentStatus'] ?? 'unpaid';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildStatusCard(status, orderData),
                if (status == 'accepted' || status == 'processing' || status == 'work_done') ...[
                  const SizedBox(height: 5),
                  _buildMapButton(),
                ],
                const SizedBox(height: 5),
                _buildOrderInfoSection(orderData),
                const SizedBox(height: 5),
                _buildItemOrderSection(orderData),
                const SizedBox(height: 5),
                _buildProblemSection(orderData),
                const SizedBox(height: 5),
                _buildCustomerInfoSection(customerId),
                const SizedBox(height: 5),
                
                // --- KARTU AKSI DINAMIS ---
                if (status == 'accepted' || status == 'processing') _buildMarkWorkDoneSection(),
                if (status == 'work_done') _buildSetPriceSection(finalAmount),
                if (paymentStatus == 'paid' && status != 'completed') _buildConfirmPaymentSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI WIDGETS (TETAP SAMA SEPERTI ASLI) ---

  Widget _buildStatusCard(String status, Map<String, dynamic> orderData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getStatusText(status), style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_formatDate(orderData['createdAt']), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PetaGelap(orderId: widget.orderId))),
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text('Lihat Lokasi Customer'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF192F65), padding: const EdgeInsets.symmetric(vertical: 12)),
      ),
    );
  }

  Widget _buildOrderInfoSection(Map<String, dynamic> orderData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Layanan', orderData['details']?['service'] ?? '-'),
          _buildInfoRow('Kategori', orderData['details']?['category'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildItemOrderSection(Map<String, dynamic> orderData) {
    return Container(); // Gunakan desain ItemOrder Anda sebelumnya
  }

  Widget _buildProblemSection(Map<String, dynamic> orderData) {
    return Container(); // Gunakan desain Kendala Anda sebelumnya
  }

  Widget _buildCustomerInfoSection(String customerId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('customers').doc(customerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              _buildInfoRow('Nama Pelanggan', data['nama'] ?? '-'),
              _buildInfoRow('Alamat', data['alamat'] ?? '-'),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () => launchUrl(Uri.parse('tel:${data['nomor_hp']}')), icon: const Icon(Icons.phone), label: const Text("Telepon"))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Komunikasi(receiverUserId: customerId))), icon: const Icon(Icons.chat), label: const Text("Chat"))),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarkWorkDoneSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isMarkingWorkDone ? null : _markWorkAsDone,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF192F65), minimumSize: const Size(double.infinity, 50)),
        child: const Text("Pekerjaan Selesai", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSetPriceSection(num? finalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text("Tetapkan Harga Akhir"),
            TextFormField(controller: _finalAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "Rp. ")),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _isSavingPrice ? null : _setFinalPrice, child: const Text("Kirim Tagihan")),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmPaymentSection() {
    return Container(); // Desain tombol konfirmasi pembayaran Anda
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}