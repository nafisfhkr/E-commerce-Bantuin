
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bantuin/main.dart'; 
import 'package:bantuin/Logic/services/pelanggan_service.dart';
import 'package:bantuin/Logic/services/auth_service.dart';
import 'package:bantuin/UI/pelanggan/editProfile.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService(FirebaseAuth.instance, FirebaseFirestore.instance, GoogleSignIn());
  List<String> _userRoles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRoles();
  }

  Future<void> _loadUserRoles() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _userRoles = List<String>.from(userDoc.get('role') ?? []);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF192F65),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profil Saya'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerProfileEditScreen())),
                ),
                const Divider(),
                if (_userRoles.length > 1 && _userRoles.contains('provider'))
                  ListTile(
                    leading: const Icon(Icons.switch_account_outlined, color: Colors.teal),
                    title: const Text('Beralih ke Mode Provider', style: TextStyle(color: Colors.teal)),
                    onTap: () async {
                      await _customerService.switchActiveRole('provider');
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/auth_wrapper', (route) => false);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () => _authService.logout().then((_) => Navigator.pushReplacementNamed(context, '/login1')),
                ),
              ],
            ),
    );
  }
}