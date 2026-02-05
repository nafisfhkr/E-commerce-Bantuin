import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Import Service
import 'package:bantuin/Logic/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  late final AuthService _authService;
  bool _isProcessing = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
      GoogleSignIn(),
    );
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Masukkan email Anda terlebih dahulu');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await _authService.sendPasswordReset(email);
      setState(() => _emailSent = true);
    } catch (e) {
      _showSnackBar('Gagal mengirim email reset. Pastikan email terdaftar.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text('Lupa Password', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_emailSent) ...[
              Text('Reset Password', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Masukkan email Anda untuk mendapatkan link reset password.', 
                style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.black,
                ),
                child: _isProcessing 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Kirim Link Reset', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ] else ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              Text('Email Terkirim!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Silakan cek inbox atau folder spam email Anda.'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.black),
                child: Text('Kembali ke Login', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}