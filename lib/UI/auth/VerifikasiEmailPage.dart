import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bantuin/Logic/services/auth_service.dart';

class VerifikasiEmailPage extends StatefulWidget {
  final String role;
  const VerifikasiEmailPage({super.key, required this.role});

  @override
  State<VerifikasiEmailPage> createState() => _VerifikasiEmailPageState();
}

class _VerifikasiEmailPageState extends State<VerifikasiEmailPage> {
  late final AuthService _authService;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Service
    _authService = AuthService(
      FirebaseAuth.instance,
      FirebaseFirestore.instance,
      GoogleSignIn(),
    );
    _email = _authService.getCurrentUserEmail();
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isVerifying = true);

    try {
      final isVerified = await _authService.checkEmailVerified();
      
      if (isVerified) {
        
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context, 
          '/profile_setup', 
          arguments: {'role': widget.role}
        );
      } else {
        _showSnackBar('Email belum diverifikasi. Silakan cek inbox Anda.');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat mengecek verifikasi.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _handleResendEmail() async {
    setState(() => _isResending = true);
    try {
      await _authService.sendEmailVerification();
      _showSnackBar('Email verifikasi telah dikirim ulang.');
    } catch (e) {
      _showSnackBar('Gagal mengirim ulang email.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text('Step 2 of 3', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.mark_email_read, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text('Verifikasi Email Anda', 
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Kami telah mengirimkan link ke:\n$_email', 
                textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
              const Spacer(),
              ElevatedButton(
                onPressed: _isVerifying ? null : _handleCheckVerification,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.black,
                ),
                child: _isVerifying 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Saya Sudah Verifikasi', style: GoogleFonts.poppins(color: Colors.white)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isResending ? null : _handleResendEmail,
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isResending 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kirim Ulang Email'),
              ),
              TextButton(
                onPressed: () => _authService.logout().then((_) => Navigator.pushReplacementNamed(context, '/login1')),
                child: const Text('Logout', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}