import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:bantuin/Logic/services/auth_service.dart';
import 'package:bantuin/UI/auth/role/confirmAddRolePage.dart';

class AddRolePage extends StatefulWidget {
  const AddRolePage({super.key});

  @override
  State<AddRolePage> createState() => _AddRolePageState();
}

class _AddRolePageState extends State<AddRolePage> {
  final AuthService _authService = AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(),
  );
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'customer'; 
  bool _isProcessing = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleProceed() async {
    if (_isProcessing) return;
    
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Email tidak boleh kosong');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Password tidak boleh kosong');
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    
    try {
      final roleUpdateData = await _authService.validateUserForRole(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
      );

      setState(() => _isProcessing = false);

      if (roleUpdateData != null) {
        if (roleUpdateData.currentRoles.contains(_selectedRole)) {
          setState(() => _errorMessage = 'Anda sudah terdaftar sebagai $_selectedRole.');
        } else {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmAddRolePage(roleData: roleUpdateData),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = 'Akun tidak ditemukan atau tidak valid.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.code == 'wrong-password' ? 'Password salah.' : 'Login gagal. Periksa email Anda.';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SvgPicture.asset('assets/images/logobantuin.svg', height: 50),
                ),
                const SizedBox(height: 10),
                Text('Tambah Role', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Tambahkan role baru ke akun Anda.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  onChanged: (val) => setState(() => _selectedRole = val!),
                  items: const [
                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'provider', child: Text('Penyedia Jasa')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Daftar Sebagai',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleProceed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.black,
                  ),
                  child: _isProcessing
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Lanjutkan', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}