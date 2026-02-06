import 'package:bantuin/Logic/model/role_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:bantuin/Logic/services/auth_service.dart';


class ConfirmAddRolePage extends StatefulWidget {
  final RoleUpdateModel roleData;

  const ConfirmAddRolePage({super.key, required this.roleData});

  @override
  State<ConfirmAddRolePage> createState() => _ConfirmAddRolePageState();
}

class _ConfirmAddRolePageState extends State<ConfirmAddRolePage> {
  final AuthService _authService = AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(),
  );

  bool _isProcessing = false;

  Future<void> _handleConfirm() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    // Memanggil fungsi finalisasi di service dengan mengirimkan model data
    final success = await _authService.finalizeRoleAddition(widget.roleData);

    if (success) {
      if (!mounted) return;
      // Navigasi ke halaman pengisian profil
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/profile_setup', 
        (route) => false, 
        arguments: {'role': widget.roleData.targetRole}
      );
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menambahkan role.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = widget.roleData.targetRole == 'customer' ? 'Customer' : 'Penyedia Jasa';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Konfirmasi Tambah Role',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.roleData.targetRole == 'customer' ? Icons.person_outline : Icons.business_center_outlined,
              size: 80, color: Colors.blue,
            ),
            const SizedBox(height: 30),
            Text('Tambah Role Baru', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Apakah Anda yakin ingin menambahkan role Anda sebagai:',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text(roleLabel, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            ),
            const SizedBox(height: 20),
            Text('Email: ${widget.roleData.email}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Batal', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isProcessing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Ya, Tambahkan', style: TextStyle(fontSize: 16, color: Colors.white)),
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