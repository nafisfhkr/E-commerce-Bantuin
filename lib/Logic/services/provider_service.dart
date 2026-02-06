import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getProviderStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot> listenForNewOrders() {
    return _db.collection('orders')
        .where('status', isEqualTo: 'pending')
        .where('providerId', isNull: true)
        .snapshots();
  }

  Future<bool> shouldNotifyOrder(String orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notified = prefs.getStringList('notifiedOrders') ?? [];
    if (notified.contains(orderId)) return false;
    
    notified.add(orderId);
    await prefs.setStringList('notifiedOrders', notified);
    return true;
  }
}