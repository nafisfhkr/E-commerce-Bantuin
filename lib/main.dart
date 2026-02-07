// File: lib/main.dart (VERSI FIX JKW)

import 'package:bantuin/UI/auth/VerifikasiEmailPage.dart';
import 'package:bantuin/UI/auth/auth_wrapper.dart';
import 'package:bantuin/UI/auth/login/login.dart';
import 'package:bantuin/UI/auth/register/registerPage.dart';
import 'package:bantuin/UI/pelanggan/pelangganDashboard.dart';
import 'package:bantuin/UI/pelanggan/pelangganOrders.dart';
import 'package:bantuin/UI/penyedia%20jasa/penyediaJasaDashboard.dart' show ProviderDashboard;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('id_ID', null);
  
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/auth_wrapper',
      routes: {
        '/auth_wrapper': (context) => const AuthWrapper(),
        '/login1': (context) => LoginPage(),
        '/register1': (context) => const RegisterPage(),
        '/dashboard_customer': (context) => const CustomerDashboard(),
        '/dashboard_provider': (context) => const ProviderDashboard(),
        '/customer_history': (context) => const CustomerOrderHistoryScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(builder: (context) => VerifikasiEmailPage(role: args['role'] ?? ''));
        }
        // 
        return null;
      },
    );
  }
}