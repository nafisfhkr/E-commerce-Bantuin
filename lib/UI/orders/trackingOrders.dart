import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';


class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderTrackingPageState createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final MapController _mapController = MapController();
  Stream<DocumentSnapshot>? _orderStream;
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _providerData;
  bool _isLoading = true;
  Timer? _refreshTimer;
  LatLng? _customerLocation;
  LatLng? _providerLocation;
  double _distance = 0;
  int _estimatedTime = 0;

  @override
  void initState() {
    super.initState();
    _setupOrderStream();
    // Refresh UI setiap 30 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupOrderStream() {
    _orderStream = FirebaseFirestore.instance
        .collection('pesanan')
        .doc(widget.orderId)
        .snapshots();

    _orderStream?.listen((snapshot) async {
      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan tidak ditemukan')),
        );
        return;
      }

      setState(() {
        _orderData = snapshot.data() as Map<String, dynamic>;
        
        // Update lokasi customer
        if (_orderData!.containsKey('lokasi_destinasi')) {
          var lokasiData = _orderData!['lokasi_destinasi'];
          _customerLocation = LatLng(
            lokasiData['latitude'], 
            lokasiData['longitude']
          );
        }

        
        if (_orderData!.containsKey('lokasi_penyedia')) {
          var lokasiPenyedia = _orderData!['lokasi_penyedia'];
          if (lokasiPenyedia['latitude'] != 0 && lokasiPenyedia['longitude'] != 0) {
            _providerLocation = LatLng(
              lokasiPenyedia['latitude'], 
              lokasiPenyedia['longitude']
            );
          }
        }

        _calculateDistanceAndTime();
      });

      if (_orderData != null && _orderData!.containsKey('penyedia_jasa_id')) {
        String providerId = _orderData!['penyedia_jasa_id'];
        
        DocumentSnapshot providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();
            
        if (providerDoc.exists) {
          setState(() {
            _providerData = providerDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      }
    });
  }

  void _calculateDistanceAndTime() {
    if (_customerLocation != null && _providerLocation != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _customerLocation!.latitude,
        _customerLocation!.longitude,
        _providerLocation!.latitude,
        _providerLocation!.longitude,
      );
      
    
      _distance = distanceInMeters / 1000;
      
      _estimatedTime = (_distance / 30 * 60).round(); 
      
      if (_estimatedTime < 5) _estimatedTime = 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Menentukan status pesanan
    String orderStatus = _orderData?['status'] ?? 'pending';
    
    return Scaffold(
      body: Stack(
        children: [
          // Peta untuk tracking
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _customerLocation ?? LatLng(-6.200000, 106.816666),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.jkw.bantuin',
              ),
              
              if (_customerLocation != null && _providerLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_customerLocation!, _providerLocation!],
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                
              MarkerLayer(
                markers: [
                  // Marker lokasi customer
                  if (_customerLocation != null)
                    Marker(
                      point: _customerLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
                    ),
                    
                  // Marker lokasi penyedia jasa
                  if (_providerLocation != null)
                    Marker(
                      point: _providerLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.handyman, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Panel detail pesanan di bagian bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status pesanan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: ${_getStatusText(orderStatus)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(orderStatus),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  if (orderStatus == 'accepted' && _providerData != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penyedia Jasa:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(Icons.person, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _providerData!['nama'] ?? 'Penyedia Jasa',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_providerLocation != null)
                                  Text(
                                    'Jarak: ${_distance.toStringAsFixed(1)} km • ${_estimatedTime} menit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () {
                                // Implementasi panggilan telepon
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  
                  // Detail layanan
                  const Text(
                    'Detail Layanan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Jenis Kendaraan:', _orderData?['jenis_perbaikan'] == 'mobil' ? 'Mobil' : 'Motor'),
                  _buildDetailRow('Layanan:', _getServiceName(_orderData?['service'] ?? '')),
                  _buildDetailRow('Biaya:', 'Rp.${_orderData?['ongkir'] ?? 0}'),
                  
                  const SizedBox(height: 16),
                  
                  
                  if (orderStatus == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Implementasi batalkan pesanan
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batalkan Pesanan'),
                      ),
                    ),
                  
                  // Tombol selesai jika sudah accepted
                  if (orderStatus == 'accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Implementasi konfirmasi selesai
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Konfirmasi Selesai'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

  }
  // Widget helper untuk menampilkan detail pesanan
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // Helper function untuk nama layanan
  String _getServiceName(String service) {
    switch (service) {
      case 'oil':
        return 'Ganti Oli';
      case 'ban':
        return 'Perbaikan Ban';
      case 'mogok':
        return 'Kendaraan Mogok';
      case 'ac':
        return 'Perbaikan AC';
      default:
        return service;
    }
  }

  // Helper function untuk teks status
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Dalam Perjalanan';
      case 'rejected':
        return 'Ditolak';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Tidak Diketahui';
    }
  }

  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}