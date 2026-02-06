import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORT SESUAI STRUKTUR BARU JKW
import 'package:bantuin/main.dart';
import 'package:bantuin/Logic/services/customer_service.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final CustomerService _service = CustomerService();
  String userName = 'Pengguna';
  bool isLoading = true;
  int _selectedIndex = 0;
  StreamSubscription? _statusSubscription;

  final List<String> _promoImages = [
    'assets/images/banner1.png',
    'assets/images/banner2.png',
    'assets/images/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _initStatusListener();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        setState(() {
          userName = doc.get('nama') ?? 'Pengguna';
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void _initStatusListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _statusSubscription = _service.listenForAcceptedOrders(uid).listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          if (data['status'] == 'accepted') {
            bool alreadyNotified = await _service.isAcceptedOrderNotified(change.doc.id);
            if (!alreadyNotified && mounted) {
              _showCustomerPopup(change.doc.id);
            }
          }
        }
      }
    });
  }

  void _showCustomerPopup(String orderId) {
    if (navigatorKey.currentState?.overlay?.context != null) {
      showDialog(
        context: navigatorKey.currentState!.overlay!.context,
        barrierDismissible: false,
        builder: (context) => NotificationCustomerScreen(orderId: orderId),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_selectedIndex) {
      case 0:
        currentBody = Column(children: [
          _buildHeader(),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(children: [_buildPromoBanner(), const SizedBox(height: 24), _buildServiceSection(context)])))
        ]);
        break;
      case 1: currentBody = const CustomerOrdersScreen(); break;
      case 2: currentBody = const ChatListPage(); break;
      case 3: currentBody = const PengaturanScreen(); break;
      default: currentBody = const Center(child: Text('Not Found'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(child: isLoading ? const Center(child: CircularProgressIndicator()) : currentBody),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // --- WIDGET UI ASLI (TIDAK BERUBAH) ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 24, backgroundImage: AssetImage('assets/images/bintang.JPG')),
          const SizedBox(width: 12),
          Text('Halo, $userName!', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return SizedBox(
      height: 230,
      child: PageView.builder(
        itemCount: _promoImages.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: AssetImage(_promoImages[index]), fit: BoxFit.cover)),
        ),
      ),
    );
  }

  Widget _buildServiceSection(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Yuk service', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _buildServiceCard('Kendaraan', 'assets/images/kendaraan.png', context)),
        const SizedBox(width: 16),
        Expanded(child: _buildServiceCard('Elektronik', 'assets/images/elektronik.png', context)),
      ]),
    ]);
  }

  Widget _buildServiceCard(String title, String imagePath, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => title == 'Kendaraan' ? const VehicleServicePage() : const ElectronicServicePage()));
      },
      child: Column(children: [
        Container(
          height: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Padding(padding: const EdgeInsets.all(6), child: Image.asset(imagePath, fit: BoxFit.contain)),
        ),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFF192F65), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(label: 'Beranda', imagePath: 'assets/images/beranda.png', index: 0),
          _buildNavItem(label: 'Riwayat', imagePath: 'assets/images/pesanan.png', index: 1),
          _buildNavItem(label: 'Pesan', imagePath: 'assets/images/pesan.png', index: 2),
          _buildNavItem(label: 'Pengaturan', imagePath: 'assets/images/pengaturan.png', index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({required String label, required String imagePath, required int index}) {
    bool isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          decoration: BoxDecoration(color: isActive ? const Color.fromARGB(255, 10, 26, 60) : Colors.transparent, borderRadius: BorderRadius.circular(25)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(imagePath, width: 24, height: 24, color: Colors.white),
            Text(label, style: GoogleFonts.poppins(fontSize: 8, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}