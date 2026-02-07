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

  Future<DocumentSnapshot> getCustomerData(String uid) async {
    return await _db.collection('customers').doc(uid).get();
  }

  Future<void> updateCustomerProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('customers').doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getOrderHistoryStream(String uid) {
    return _db.collection('orders')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getOrderDetailStream(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots();
  }

  Future<void> cancelOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({'status': 'cancelled'});
  }

  Future<void> switchActiveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_role', role);
  }
}