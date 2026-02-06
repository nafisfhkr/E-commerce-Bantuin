import 'package:bantuin/Logic/model/auth_model.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bantuin/Logic/model/role_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService(this._auth, this._firestore, this._googleSignIn);

  
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser!.emailVerified;
    }
    return false;
  }

  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }


  Future<AuthResult> signInWithGoogle(String selectedLoginRole) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(status: AuthStatus.error, errorMessage: 'Login Google dibatalkan.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      return await _processUserLogin(user, selectedLoginRole, isNewGoogleUser: false);
    } catch (e) {
      print('Login Google gagal: $e');
      return AuthResult(status: AuthStatus.error, errorMessage: 'Login Google gagal: $e');
    }
  }

  Future<AuthResult> signInWithEmailPassword(String email, String password, String selectedLoginRole) async {
    final emailTrimmed = email.trim();
    final passwordTrimmed = password.trim();

    if (emailTrimmed.isEmpty && passwordTrimmed.isEmpty) {
      return AuthResult(status: AuthStatus.inputError, errorMessage: 'Email dan password tidak boleh kosong');
    }
    if (emailTrimmed.isEmpty) {
      return AuthResult(status: AuthStatus.inputError, errorMessage: 'Email tidak boleh kosong');
    }
    if (passwordTrimmed.isEmpty) {
      return AuthResult(status: AuthStatus.inputError, errorMessage: 'Password tidak boleh kosong');
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailTrimmed,
        password: passwordTrimmed,
      );

      final user = userCredential.user!;
      return await _processUserLogin(user, selectedLoginRole);
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          errorMessage = 'Email atau password salah, atau email Anda belum terdaftar.';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          errorMessage = 'Akun Anda telah dinonaktifkan.';
          break;
        default:
          errorMessage = 'Login gagal. Coba lagi.';
      }
      return AuthResult(status: AuthStatus.error, errorMessage: errorMessage);
    } catch (e) {
      print('Login gagal: $e');
      return AuthResult(status: AuthStatus.error, errorMessage: 'Login gagal: $e');
    }
  }

  Future<AuthResult> _processUserLogin(User user, String selectedRole, {bool isNewGoogleUser = false}) async {
    final uid = user.uid;

    if (!user.emailVerified) {
      await user.sendEmailVerification();
      return AuthResult(status: AuthStatus.emailNotVerified, role: selectedRole);
    }

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'email': user.email,
        'role': [selectedRole],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _createRoleDocument(uid, selectedRole);
      return AuthResult(status: AuthStatus.success, user: user, role: selectedRole);
    }

    List<String> roles = [];
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    if (userData.containsKey('role')) {
      if (userData['role'] is List) {
        roles = List<String>.from(userData['role']);
      } else {
        roles = [userData['role']];
      }
    }

    if (!roles.contains(selectedRole)) {
      if (isNewGoogleUser) {
        roles.add(selectedRole);
        await _firestore.collection('users').doc(uid).update({'role': roles});
      } else {
        return AuthResult(status: AuthStatus.roleNotAvailable);
      }
    }

    final roleCollection = selectedRole == 'customer' ? 'customers' : 'providers';
    final roleDoc = await _firestore.collection(roleCollection).doc(uid).get();
        
    if (!roleDoc.exists) {
      await _createRoleDocument(uid, selectedRole);
    }
    
    return AuthResult(status: AuthStatus.success, user: user, role: selectedRole);
  }

  Future<void> _createRoleDocument(String uid, String role) async {
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
      print('Gagal membuat dokumen role: $e');
      rethrow;
    }
  }
  Future<bool> isEmailRegistered(String email) async {
    final signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim());
    return signInMethods.isNotEmpty;
  }

  Future<AuthResult> createAccount(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      final user = userCredential.user!;
      await user.sendEmailVerification();

      
      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'role': [role],
        'createdAt': FieldValue.serverTimestamp(),
      });

      
      await _createRoleDocument(user.uid, role);

      return AuthResult(status: AuthStatus.success, role: role);
    } on FirebaseAuthException catch (e) {
      return AuthResult(status: AuthStatus.error, errorMessage: _handleAuthException(e));
    } catch (e) {
      return AuthResult(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<AuthResult> loginAndAddRole(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = userCredential.user!.uid;
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        List<String> roles = List<String>.from(userDoc.get('role') ?? []);
        if (!roles.contains(role)) {
          roles.add(role);
          await userDocRef.update({'role': roles});
          await _createRoleDocument(uid, role);
          return AuthResult(status: AuthStatus.success, role: role);
        } else {
          return AuthResult(status: AuthStatus.roleNotAvailable);
        }
      }
      return AuthResult(status: AuthStatus.error, errorMessage: 'Data user tidak ditemukan.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(status: AuthStatus.error, errorMessage: _handleAuthException(e));
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password': return 'Password terlalu lemah.';
      case 'email-already-in-use': return 'Email sudah digunakan.';
      case 'invalid-email': return 'Format email tidak valid.';
      case 'wrong-password': return 'Password salah.';
      default: return 'Terjadi kesalahan: ${e.message}';
    }
  }

  Future<RoleUpdateModel?> validateUserForRole(String email, String password, String targetRole) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
      
      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        var rolesData = userDoc.data()!['role'];
        List<String> roles = rolesData is List ? List<String>.from(rolesData) : [rolesData.toString()];

        return RoleUpdateModel(
          email: email,
          targetRole: targetRole,
          currentRoles: roles,
        );
      }
      return null;
    } catch (e) {
      rethrow; 
    }
  }

  
  Future<bool> finalizeRoleAddition(RoleUpdateModel data) async {
    try {
      final uid = _auth.currentUser!.uid;
      List<String> updatedRoles = List.from(data.currentRoles);
      
      if (!updatedRoles.contains(data.targetRole)) {
        updatedRoles.add(data.targetRole);
      }
      
      await _firestore.collection('users').doc(uid).update({'role': updatedRoles});
      await _createRoleDocument(uid, data.targetRole);
      
      return true;
    } catch (e) {
      return false;
    }
  }
}