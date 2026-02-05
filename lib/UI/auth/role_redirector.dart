import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleRedirector extends StatefulWidget {
  const RoleRedirector({super.key});

  @override
  State<RoleRedirector> createState() => _RoleRedirectorState();
}

class _RoleRedirectorState extends State<RoleRedirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectUser();
    });
  }

  Future<void> _redirectUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login1');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeRole = prefs.getString('active_role');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final roles = List<String>.from(userDoc.get('role') ?? []);
        
        if (roles.contains('provider') && activeRole == 'provider') {
          Navigator.pushReplacementNamed(context, '/dashboard_provider');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard_customer');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login1');
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}