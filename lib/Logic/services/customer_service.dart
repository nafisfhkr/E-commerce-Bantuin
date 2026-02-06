import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<DocumentSnapshot> getCustomerStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot> listenForAcceptedOrders(String uid) {
    return _db.collection('orders')
        .where('customerId', isEqualTo: uid)
        .snapshots();
  }

  Future<bool> isAcceptedOrderNotified(String orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notified = prefs.getStringList('notifiedAcceptedOrders_customer') ?? [];
    if (notified.contains(orderId)) return true;

    notified.add(orderId);
    await prefs.setStringList('notifiedAcceptedOrders_customer', notified);
    return false;
  }
}