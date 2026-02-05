

import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  success,
  emailNotVerified,
  roleNotAvailable,
  error,
  inputError
}

class AuthResult {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? role; 

  AuthResult({
    required this.status,
    this.user,
    this.errorMessage,
    this.role,
  });
}