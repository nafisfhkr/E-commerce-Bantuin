import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class ProviderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- DASHBOARD & NOTIFIKASI ---
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

  // --- KELOLA PESANAN (MengeolahPesanan) ---
  Stream<List<QueryDocumentSnapshot>> getCombinedOrdersStream(String uid) {
    Stream<QuerySnapshot> pending = _db.collection('orders')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    Stream<QuerySnapshot> ongoing = _db.collection('orders')
        .where('providerId', isEqualTo: uid)
        .where('status', whereIn: ['accepted', 'work_done'])
        .snapshots();

    return CombineLatestStream.combine2(pending, ongoing, (QuerySnapshot p, QuerySnapshot o) {
      final List<QueryDocumentSnapshot> list = [];
      list.addAll(p.docs);
      list.addAll(o.docs);
      list.sort((a, b) {
        Timestamp timeA = a['createdAt'] ?? Timestamp.now();
        Timestamp timeB = b['createdAt'] ?? Timestamp.now();
        return timeB.compareTo(timeA);
      });
      return list;
    }).asBroadcastStream();
  }

  Stream<QuerySnapshot> getCompletedOrdersStream(String uid) {
    return _db.collection('orders')
        .where('status', isEqualTo: 'completed')
        .where('providerId', isEqualTo: uid)
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  // ---MANAJEMEN LAYANAN ---
  Future<void> saveActiveServices(String uid, Map<String, dynamic> services) async {
    await _db.collection('providers').doc(uid).set({'activeServices': services}, SetOptions(merge: true));
  }
}