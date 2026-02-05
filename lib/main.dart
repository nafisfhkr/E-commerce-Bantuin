import 'package:bantuin/UI/auth/login/login.dart';
import 'package:bantuin/UI/auth/register/registerPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bantuin/UI/auth/VerifikasiEmailPage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
 
  await initializeDateFormatting('id_ID', null);


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Bantuin JKW',
      initialRoute: '/login1',
      routes: {
        '/login1': (context) => LoginPage(),
        '/register1': (context) => const RegisterPage(),
        '/dashboard_customer': (context) => const Scaffold(body: Center(child: Text("Dashboard Customer"))),
        '/dashboard_provider': (context) => const Scaffold(body: Center(child: Text("Dashboard Provider"))),
      },
    );
  }
}