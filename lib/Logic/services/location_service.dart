import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationTimer;
  String? _currentOrderId;
  bool _isTracking = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> startTracking(String orderId) async {
    if (_isTracking) {
      await stopTracking();
    }

    _currentOrderId = orderId;
    _isTracking = true;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen, buka pengaturan untuk mengubahnya');
    }

    
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _updateLocation();
    });

   
    await _updateLocation();
  }

 
  Future<void> stopTracking() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _currentOrderId = null;
    _isTracking = false;
  }

  Future<void> _updateLocation() async {
    try {
      if (!_isTracking || _currentOrderId == null) return;

      User? user = _auth.currentUser;
      if (user == null) return;

      Position position = await Geolocator.getCurrentPosition();

      await _firestore.collection('pesanan').doc(_currentOrderId).update({
        'lokasi_penyedia': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_updated': Timestamp.now(),
        },
      });

      await _firestore
          .collection('pesanan')
          .doc(_currentOrderId)
          .collection('location_history')
          .add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'provider_id': user.uid,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  bool get isTracking => _isTracking;
  String? get currentOrderId => _currentOrderId;
}