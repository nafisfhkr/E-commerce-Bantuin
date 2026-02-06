import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORT SESUAI STRUKTUR BARU JKW
import 'package:bantuin/main.dart'; 
import 'package:bantuin/Logic/services/provider_service.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  final ProviderService _service = ProviderService();
  bool _isAmountVisible = true;
  StreamSubscription? _orderListener;

  @override
  void initState() {
    super.initState();
    _setupOrderListener();
  }

  @override
  void dispose() {
    _orderListener?.cancel();
    super.dispose();
  }

  void _setupOrderListener() {
    _orderListener = _service.listenForNewOrders().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          bool shouldNotify = await _service.shouldNotifyOrder(change.doc.id);
          if (shouldNotify && mounted) {
            _showNotificationPopup(change.doc.id);
          }
        }
      }
    });
  }

  void _showNotificationPopup(String orderId) {
    if (navigatorKey.currentState?.overlay?.context != null) {
      showDialog(
        context: navigatorKey.currentState!.overlay!.context,
        barrierDismissible: false,
        builder: (context) => NotificationProviderScreen(orderId: orderId),
      );
    }
  }

  void _toggleAmountVisibility() {
    setState(() => _isAmountVisible = !_isAmountVisible);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Sesi berakhir")));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _service.getProviderStream(user.uid),
          builder: (context, snapshot) {
            final userData = snapshot.hasData ? snapshot.data!.data() as Map<String, dynamic>? : null;
            final currentUserName = userData?['nama'] ?? 'Bambang';
            final profileImageUrl = userData?['profileImageUrl'] ?? 'assets/images/bintang.JPG';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(currentUserName, profileImageUrl),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildIncomeBanner(userData),
                          const SizedBox(height: 16),
                          _buildStatisticsRow(userData),
                          const SizedBox(height: 20),
                          _buildStoreManagementSection(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // --- WIDGET UI ASLI (TIDAK BERUBAH) ---
  Widget _buildHeader(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: imageUrl.startsWith('http') ? NetworkImage(imageUrl) : AssetImage(imageUrl) as ImageProvider,
              ),
              const SizedBox(width: 10),
              Text('Hello, $name!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {}, iconSize: 22, color: Colors.black),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}, iconSize: 22, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBanner(Map<String, dynamic>? userData) {
    final totalPenghasilan = (userData?['totalPenghasilan'] ?? 8000000.0).toDouble();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF192F6A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Penghasilan Bulan ini', style: TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(text: TextSpan(children: [
                const TextSpan(text: 'Rp. ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                TextSpan(
                  text: _isAmountVisible ? currencyFormatter.format(totalPenghasilan) : '••••••••',
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ])),
              IconButton(
                icon: Icon(_isAmountVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 22),
                onPressed: _toggleAmountVisibility,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: const Text('+15% dari bulan lalu', style: TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(Map<String, dynamic>? userData) {
    final pesananSelesai = userData?['pesananSelesai'] ?? 27;
    final rataRataRating = (userData?['rataRataRating'] ?? 4.85).toDouble();
    return Row(children: [
      Expanded(child: _buildStatCard('Pesanan selesai', pesananSelesai.toString())),
      const SizedBox(width: 8),
      Expanded(child: _buildStatCard('Rata-rata Rating', rataRataRating.toStringAsFixed(2))),
    ]);
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildStoreManagementSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Kelola Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _buildMenuCardWithImage(imagePath: 'assets/images/barang.png', title: 'Manajemen Barang', onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _buildMenuCardWithImage(imagePath: 'assets/images/layanan.png', title: 'Manajemen Layanan', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ManajemenLayananPage()));
        })),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _buildMenuCardWithImage(imagePath: 'assets/images/penghasilan.png', title: 'Penghasilan', onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _buildMenuCardWithImage(imagePath: 'assets/images/ulasan2.png', title: 'Ulasan', onTap: () {}, isReview: true)),
      ]),
    ]);
  }

  Widget _buildMenuCardWithImage({required String imagePath, required String title, required Function() onTap, bool isReview = false}) {
    Widget iconWidget = isReview 
      ? Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFF1A2F69), shape: BoxShape.circle), child: const Icon(Icons.star, color: Colors.yellow))
      : Image.asset(imagePath, width: 48, height: 48, color: const Color(0xFF1A2F69));
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          iconWidget, const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFF192F65), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(label: 'Beranda', icon: Icons.home_filled, index: 0),
          _buildNavItem(label: 'Pesanan', icon: Icons.receipt_long, index: 1),
          _buildNavItem(label: 'Pesan', icon: Icons.chat_bubble, index: 2),
          _buildNavItem(label: 'Pengaturan', icon: Icons.settings, index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({required String label, required IconData icon, required int index}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderManagementScreen()));
          else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
          else if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderSettingsScreen()));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: index == 0 ? Colors.white : Colors.white.withOpacity(0.7)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}