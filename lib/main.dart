import 'package:bantuin/UI/auth/VerifikasiEmailPage.dart';
import 'package:bantuin/UI/auth/auth_wrapper.dart';
import 'package:bantuin/UI/auth/login/login.dart';
import 'package:bantuin/UI/auth/register/registerPage.dart';
import 'package:bantuin/UI/chat/komunikasi.dart';
import 'package:bantuin/UI/maps/peta_driver.dart';
import 'package:bantuin/UI/opening/openinganimasi.dart';
import 'package:bantuin/UI/orders/elektronikOrders.dart';
import 'package:bantuin/UI/orders/kendaraanOrders.dart';
import 'package:bantuin/UI/orders/trackingOrders.dart';
import 'package:bantuin/UI/pelanggan/pelangganDashboard.dart';
import 'package:bantuin/UI/pelanggan/pelangganOrders.dart';
import 'package:bantuin/UI/penyedia%20jasa/penyediaJasaDashboard.dart' show ProviderDashboard;
import 'package:bantuin/UI/profiles/profileSetUp.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';




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
      initialRoute: '/opening_animation',
      routes: {
        '/opening_animation': (context) => const OpeningAnimationScreen(),
        '/auth_wrapper': (context) => const AuthWrapper(),
        '/login1': (context) => LoginPage(),
        '/register1': (context) => const RegisterPage(),
        '/dashboard_customer': (context) => const CustomerDashboard(),
        '/dashboard_provider': (context) => const ProviderDashboard(),
        '/customer_history': (context) => const CustomerOrderHistoryScreen(),
        '/vehicle_service': (context) => const VehicleServicePage(),
        '/electronic_service': (context) => const ElectronicServicePage(),
        '/tracking': (context) => OrderTrackingPage(orderId: ModalRoute.of(context)!.settings.arguments as String),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verification') {
           final args = settings.arguments as Map<String, dynamic>? ?? {};
           return MaterialPageRoute(builder: (context) => VerifikasiEmailPage(role: args['role'] ?? ''));
        } else if (settings.name == '/profile_setup') {
           final args = settings.arguments as Map<String, dynamic>? ?? {};
           return MaterialPageRoute(builder: (context) => ProfileSetupPage(role: args['role'] ?? ''));
        } else if (settings.name == '/chat') {
           final args = settings.arguments as Map<String, dynamic>? ?? {};
           return MaterialPageRoute(builder: (context) => Komunikasi(receiverUserId: args['receiverUserId'] as String? ?? ''));
        } else if (settings.name == '/peta') {
           final args = settings.arguments as Map<String, dynamic>?;
           if (args != null && args['orderId'] != null) {
             return MaterialPageRoute(builder: (context) => PetaGelap(orderId: args['orderId'] as String));
           }
        }
        return null;
      },
    );
  }
}