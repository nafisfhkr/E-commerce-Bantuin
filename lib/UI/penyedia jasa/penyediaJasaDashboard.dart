import 'dart:async';
import 'package:bantuin/UI/chat/chatList.dart';
import 'package:bantuin/UI/notifikasi/notifikasiPenyediaJasa.dart';
import 'package:bantuin/UI/penyedia%20jasa/penyediaJasaSettings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:bantuin/main.dart';
import 'package:bantuin/Logic/services/penyediaJasa_service.dart';
import 'package:bantuin/UI/penyedia jasa/manajemenPesanan.dart';
import 'package:bantuin/UI/penyedia jasa/manajemenJasa.dart';

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
    _initOrderListener();
  }

  @override
  void dispose() {
    _orderListener?.cancel();
    super.dispose();
  }

  void _initOrderListener() {
    _orderListener = _service.listenForNewOrders().listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          bool notify = await _service.shouldNotifyOrder(change.doc.id);
          if (notify && mounted) _showPopup(change.doc.id);
        }
      }
    });
  }

  void _showPopup(String orderId) {
    if (navigatorKey.currentState?.overlay?.context != null) {
      showDialog(
        context: navigatorKey.currentState!.overlay!.context,
        barrierDismissible: false,
        builder: (context) => NotificationProviderScreen(orderId: orderId),
      );
    }
  }

  void _toggleAmountVisibility() {
    setState(() {
      _isAmountVisible = !_isAmountVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _service.getProviderStream(user!.uid),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final currentUserName = userData?['nama'] ?? 'Provider';
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

  Widget _buildHeader(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
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
              IconButton(icon: const Icon(Icons.search), onPressed: () {}, iconSize: 22, color: Colors.black, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}, iconSize: 22, color: Colors.black, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Penghasilan Bulan ini', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(text: TextSpan(children: [
                const TextSpan(text: 'Rp. ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                TextSpan(
                  text: _isAmountVisible ? currencyFormatter.format(totalPenghasilan) : '••••••••',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 22, fontWeight: FontWeight.bold),
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
            child: const Text('+15% dari bulan lalu', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
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
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }
  
  Widget _buildStoreManagementSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Kelola Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _buildMenuCardWithImage(imagePath: 'assets/images/barang.png', title: 'Manajemen Barang', onTap: () {})),
        const SizedBox(width: 10),
        Expanded(child: _buildMenuCardWithImage(imagePath: 'assets/images/layanan.png', title: 'Manajemen Layanan', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManajemenLayananPage()),
          );
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
     Widget iconWidget;
    if (isReview) {
      iconWidget = Container(width: 48, height: 48, decoration: const BoxDecoration(color: Color(0xFF1A2F69), shape: BoxShape.circle), child: const Center(child: Icon(Icons.star, size: 48 * 0.6, color: Colors.yellow)));
    } else {
      iconWidget = Image.asset(imagePath, width: 48, height: 48, color: const Color(0xFF1A2F69));
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          iconWidget, const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFF192F65), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))]),
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
    final selectedIndex = 0; 
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (context) => OrderManagementScreen()));
          else if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (context) => ChatListPage()));
          else if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderSettingsScreen()));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selectedIndex == index ? Colors.white : Colors.white.withOpacity(0.7)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: selectedIndex == index ? Colors.white : Colors.white.withOpacity(0.7), fontWeight: selectedIndex == index ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}