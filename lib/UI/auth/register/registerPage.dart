import 'package:bantuin/UI/auth/VerifikasiEmailPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (password.length < 8) {
      return 'Password minimal 8 karakter';
    }
    
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    
    if (!(hasUppercase && hasLowercase && hasDigit)) {
      return 'Password harus mengandung huruf besar, huruf kecil, dan angka';
    }
    
    return null;
  }

  Future<void> _registerWithEmail(BuildContext context) async {
    if (_isProcessing) return; 
    
 
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email tidak boleh kosong')),
      );
      return;
    }
    
    final passwordError = validatePassword(_passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password tidak sama')),
      );
      return;
    }
    
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda harus menyetujui syarat dan ketentuan')),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        _showPasswordConfirmDialog(context, email, password);
      } else {
        await _createNewAccount(context, email, password);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPasswordConfirmDialog(BuildContext context, String email, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Sudah Terdaftar'),
        content: Text(
          'Email ini sudah terdaftar. Jika ini adalah akun Anda dan ingin menambahkan role baru, '
          'silakan masukkan password untuk mengkonfirmasi.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _loginAndAddRole(context, email, password);
            },
            child: Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

 
  Future<void> _loginAndAddRole(BuildContext context, String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      
     
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        List<String> roles = [];
        
        if (userDoc.data()?.containsKey('role') ?? false) {
          roles = userDoc.data()?['role'] is List
              ? List<String>.from(userDoc.data()?['role'])
              : [userDoc.data()?['role']];
        }

        if (!roles.contains(_selectedRole)) {
         
          roles.add(_selectedRole);
          await userDocRef.update({'role': roles});
          
       
          await _saveRoleData(uid, _selectedRole);
          
         
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerifikasiEmailPage(role: _selectedRole),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Anda sudah memiliki role $_selectedRole.')),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      } else {
        await userDocRef.set({
          'email': email,
          'role': [_selectedRole],
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await _saveRoleData(uid, _selectedRole);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifikasiEmailPage(role: _selectedRole),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password salah. Silakan coba lagi.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login: ${e.message}')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _createNewAccount(BuildContext context, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user!.uid;
      
      await userCredential.user!.sendEmailVerification();

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': [_selectedRole],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _saveRoleData(uid, _selectedRole);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerifikasiEmailPage(role: _selectedRole),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      String errorMessage = 'Terjadi kesalahan saat mendaftar.';
      
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _saveRoleData(String uid, String role) async {
    final timestamp = FieldValue.serverTimestamp();
    
    try {
      if (role == 'customer') {
        final customerDoc = await _firestore.collection('customers').doc(uid).get();
        if (!customerDoc.exists) {
          await _firestore.collection('customers').doc(uid).set({
            'nama': '',
            'alamat': '',
            'nomor_hp': '',
            'photo_url': '',
            'createdAt': timestamp,
          });
        }
      } else if (role == 'provider') {
        final providerDoc = await _firestore.collection('providers').doc(uid).get();
        if (!providerDoc.exists) {
          await _firestore.collection('providers').doc(uid).set({
            'nama_usaha': '',
            'deskripsi': '',
            'kategori': '',
            'alamat_usaha': '',
            'nomor_hp': '',
            'rating': 0.0,
            'photo_url': '',
            'status_verifikasi': 'pending',
            'createdAt': timestamp,
          });
        }
      }
    } catch (e) {
      print('Gagal menyimpan data role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data role: $e')),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Spacer(),
                    Text(
                      'Step 1 of 3',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 20),
                Center(
                  child: SvgPicture.asset(
                    'assets/images/email_icon.svg',
                    height: 50,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Create Account',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'To get started, create an account.',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    errorText: _passwordError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _passwordError = validatePassword(value);
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                  items: [
                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'provider', child: Text('Penyedia Jasa')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Daftar Sebagai',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptedTerms = !_acceptedTerms;
                          });
                        },
                        child: Text(
                          'I confirm that I have thoroughly read and agree to the terms outlined in our User Agreement and Privacy Policy.',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null  
                      : () => _registerWithEmail(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.black,
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}