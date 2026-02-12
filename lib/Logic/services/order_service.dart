import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentReference> createNewOrder(Map<String, dynamic> orderData) async {
    return await _db.collection('orders').add(orderData);
  }
}