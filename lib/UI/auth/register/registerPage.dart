

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bantuin/Logic/services/auth_service.dart';
import 'package:bantuin/Logic/model/auth_model.dart';
import 'package:bantuin/UI/auth/VerifikasiEmailPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Inisialisasi Service
  final AuthService _authService = AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(),
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'customer';
  bool _isProcessing = false;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;

  String? validatePassword(String password) {
    if (password.isEmpty) return 'Password tidak boleh kosong';
    if (password.length < 8) return 'Password minimal 8 karakter';
    if (!password.contains(RegExp(r'[A-Z]')) || !password.contains(RegExp(r'[a-z]')) || !password.contains(RegExp(r'[0-9]'))) {
      return 'Harus mengandung huruf besar, kecil, dan angka';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_isProcessing) return;


    if (_emailController.text.isEmpty) {
      _showSnackBar('Email tidak boleh kosong');
      return;
    }
    if (validatePassword(_passwordController.text) != null) {
      _showSnackBar(validatePassword(_passwordController.text)!);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Password tidak sama');
      return;
    }
    if (!_acceptedTerms) {
      _showSnackBar('Anda harus menyetujui syarat dan ketentuan');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      
      final isRegistered = await _authService.isEmailRegistered(email);

      if (isRegistered) {
        _showPasswordConfirmDialog(email, password);
      } else {
        
        final result = await _authService.createAccount(email, password, _selectedRole);
        _processAuthResult(result);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showPasswordConfirmDialog(String email, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Sudah Terdaftar'),
        content: const Text('Email ini sudah terdaftar. Masukkan password untuk menambahkan role baru.'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            setState(() => _isProcessing = false);
          }, child: const Text('Batal')),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            final result = await _authService.loginAndAddRole(email, password, _selectedRole);
            _processAuthResult(result);
          }, child: const Text('Konfirmasi')),
        ],
      ),
    );
  }

  void _processAuthResult(AuthResult result) {
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.status == AuthStatus.success || result.status == AuthStatus.emailNotVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerifikasiEmailPage(role: _selectedRole)),
      );
    } else if (result.status == AuthStatus.roleNotAvailable) {
      _showSnackBar('Anda sudah memiliki role $_selectedRole.');
    } else {
      _showSnackBar(result.errorMessage ?? 'Gagal mendaftar.');
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
          child: SingleChildScrollView(
            child: Column(
              children: [
              
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.black,
                  ),
                  child: _isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Continue', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}