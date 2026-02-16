

import 'package:bantuin/UI/auth/login/login.dart'; 
import 'package:bantuin/UI/penyedia jasa/penyediaJasaProfileEdit.dart';
import 'package:bantuin/UI/auth/auth_wrapper.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
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
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted && userDoc.exists) {
          setState(() {
            _userRoles = List<String>.from(userDoc.get('role') ?? []);
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Gagal memuat peran pengguna: $e");
        if(mounted) setState(() => _isLoading = false);
      }
    } else {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _switchToRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_role', role);

    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AuthWrapper()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Apakah Anda yakin ingin logout?', style: GoogleFonts.poppins()),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          actionsAlignment: MainAxisAlignment.end,
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF192F6A),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: <Widget>[
                _buildSectionTitle('Akun & Jasa'),
                ListTile(
                  leading: Icon(Icons.storefront_outlined, color: Theme.of(context).primaryColorDark),
                  title: Text('Profil Toko / Jasa', style: GoogleFonts.poppins()),
                  subtitle: Text('Atur nama, deskripsi, dan info jasa Anda', style: GoogleFonts.poppins(fontSize: 12)),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProviderProfileEditScreen()),
                    );
                  },
                ),
                Divider(),

                if (_userRoles.length > 1 && _userRoles.contains('customer'))
                  ListTile(
                    leading: Icon(Icons.switch_account_outlined, color: Colors.teal),
                    title: Text('Beralih ke Mode Customer', style: GoogleFonts.poppins(color: Colors.teal, fontWeight: FontWeight.w500)),
                    onTap: () => _switchToRole('customer'),
                  ),
                if (_userRoles.length > 1) Divider(),
                
                _buildSectionTitle('Keamanan'),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                  onTap: () => _logout(context),
                ),
                Divider(),
              ],
            ),
    );
  }

 
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}