import 'package:bantuin/UI/auth/register/registerPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bantuin/UI/auth/VerifikasiEmailPage.dart';
import 'package:bantuin/UI/auth/ForgotPasswordPage.dart';
import 'package:bantuin/Logic/services/auth_service.dart';
import 'package:bantuin/Logic/model/auth_model.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(),
  );
  // -----------------------

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedLoginRole = 'customer';
  bool _isProcessing = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 3;

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    final result = await _authService.signInWithGoogle(_selectedLoginRole);

    setState(() {
      _isProcessing = false;
    });

    _handleAuthResult(result);
  }

  
  Future<void> _signInWithEmailPassword(BuildContext context) async {
    if (_isProcessing) return;
   
    final stopwatch = Stopwatch()..start();
    print('Test Dimulai');

    setState(() {
      _isProcessing = true;
    });
    
    
    final result = await _authService.signInWithEmailPassword(
      _emailController.text,
      _passwordController.text,
      _selectedLoginRole,
    );

    stopwatch.stop();
    print(' Test Selesai. Durasi Login: ${stopwatch.elapsedMilliseconds} ms');

    setState(() {
      _isProcessing = false;
    });

    
    _handleAuthResult(result);
  }

  void _handleAuthResult(AuthResult result) {
    if (!mounted) return;

    switch (result.status) {
      case AuthStatus.success:
        _failedAttempts = 0; // Reset counter
        _navigateToDashboard(result.role!);
        break;

      case AuthStatus.emailNotVerified:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerifikasiEmailPage(role: result.role!)),
        );
        break;

      case AuthStatus.roleNotAvailable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda belum terdaftar sebagai $_selectedLoginRole. Silakan tambahkan role baru.')),
        );
        Navigator.pushNamed(context, '/add_role');
        break;

      case AuthStatus.inputError:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Input tidak valid.')),
        );
        break;

      case AuthStatus.error:
        _failedAttempts++;
        String errorMessage = result.errorMessage ?? 'Login gagal.';

        if (_failedAttempts >= _maxFailedAttempts) {
          _showTooManyAttemptsDialog(context);
          return; 
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage ($_failedAttempts/$_maxFailedAttempts)'),
            duration: Duration(seconds: 3),
          ),
        );
        break;
    }
  }

  void _showTooManyAttemptsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Terlalu Banyak Percobaan'),
        content: Text(
          'Anda telah gagal login $_maxFailedAttempts kali. '
          'Untuk keamanan, silakan ganti password Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
              );
            },
            child: Text('Ganti Password'),
          ),
        ],
      ),
    );
  }

 
  void _navigateToDashboard(String role) {
    if (role == 'customer') {
      Navigator.pushReplacementNamed(context, '/dashboard_customer');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard_provider');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext content) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/logobantuin.svg',
                              height: 40,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Bantuin',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Service kapanpun dimanapun',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 30),
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
                        SizedBox(height: 20),
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
                          ),
                        ),
                        SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedLoginRole,
                          onChanged: (value) {
                            setState(() {
                              _selectedLoginRole = value!;
                            });
                          },
                          items: [
                            DropdownMenuItem(
                                value: 'customer',
                                child: Text('Masuk sebagai Customer')),
                            DropdownMenuItem(
                                value: 'provider',
                                child: Text('Masuk sebagai Penyedia Jasa')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Login sebagai',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Text(
                                  'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi.',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              // Panggil fungsi yang sudah di-refactor
                              : () => _signInWithEmailPassword(context),
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
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(Icons.person_add),
                                label: Text('Register'),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/add_role');
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(Icons.add_circle_outline),
                                label: Text('Tambah Role'),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        OutlinedButton(
                          key: const Key('google_login_button'),
                          onPressed: _isProcessing
                              ? null
                              // Panggil fungsi yang sudah di-refactor
                              : () => _signInWithGoogle(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/googlelogo.png',
                                height: 24,
                              ),
                              SizedBox(width: 10),
                              Text('Login dengan Google'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordPage()
                              )
                            );
                          },
                          child: Text('Lupa Password?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}