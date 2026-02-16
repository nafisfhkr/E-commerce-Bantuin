import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; 
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bantuin/Logic/config.dart'; 

class PetaGelap extends StatefulWidget {
  final String orderId;
  const PetaGelap({Key? key, required this.orderId}) : super(key: key);

  @override
  _PetaGelapState createState() => _PetaGelapState();
}

class _PetaGelapState extends State<PetaGelap> {
  GoogleMapController? _mapController;
  bool _isActionInProgress = false;
  

  Map<MarkerId, Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];
  PolylinePoints _polylinePoints = PolylinePoints();

 
  final String _darkMapStyle = '''[
    {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
    {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
    {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
    {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  Future<void> _getPolyline(LatLng start, LatLng end) async {
    _polylines.clear();
    _polylineCoordinates.clear();

    PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: MAPS_API_KEY,
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(end.latitude, end.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          points: _polylineCoordinates,
          color: Colors.blueAccent,
          width: 5,
        ));
      });
    }
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { return; }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !mounted) return;
      
      try {
        final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
        if (orderDoc.exists && orderDoc.data()?['providerId'] == user.uid) {
          await orderDoc.reference.update({
            'providerLocation': GeoPoint(position.latitude, position.longitude),
          });
        }
      } catch (e) { print("Error updating provider location: $e"); }
    });
  }

  Future<void> _customerPay(num amount, String providerId, String customerId) async {
  }

  Future<void> _providerConfirmPaymentAndCompleteOrder() async {
    if (mounted) setState(() { _isActionInProgress = true; });
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'paymentStatus': 'confirmed',
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran dikonfirmasi & pesanan selesai!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e. Periksa Firestore Rules.')));
    } finally {
      if (mounted) setState(() { _isActionInProgress = false; });
    }
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return 'N/A';
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var orderData = snapshot.data!.data() as Map<String, dynamic>;
          GeoPoint? custLoc = orderData['customerLocation'];
          GeoPoint? provLoc = orderData['providerLocation'];

          if (custLoc == null) return const Center(child: Text('Lokasi tidak ditemukan'));

          LatLng customerLatLng = LatLng(custLoc.latitude, custLoc.longitude);
          LatLng? providerLatLng = provLoc != null ? LatLng(provLoc.latitude, provLoc.longitude) : null;

          if (providerLatLng != null && _polylineCoordinates.isEmpty) {
            _getPolyline(providerLatLng, customerLatLng);
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: customerLatLng, zoom: 15),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _mapController!.setMapStyle(_darkMapStyle); 
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('customer'),
                    position: customerLatLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                  ),
                  if (providerLatLng != null)
                    Marker(
                      markerId: const MarkerId('provider'),
                      position: providerLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                      infoWindow: const InfoWindow(title: 'Teknisi'),
                    ),
                },
                polylines: _polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),

            
              Positioned(
                top: 40, left: 16,
                child: SafeArea(
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),

              DraggableScrollableSheet(
                initialChildSize: 0.35, minChildSize: 0.15, maxChildSize: 0.6,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(blurRadius: 10.0, color: Colors.black.withOpacity(0.2))],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        Center(
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 12),
                            width: 40, height: 5,
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        _buildDynamicBottomContent(orderData),
                      ],
                    ),
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicBottomContent(Map<String, dynamic> orderData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final status = orderData['status'] ?? 'pending';
    final paymentStatus = orderData['paymentStatus'] ?? 'unpaid';
    final finalAmount = orderData['finalAmount'];
    final providerId = orderData['providerId'];
    final isCustomer = user.uid == orderData['customerId'];
    final isProvider = user.uid == orderData['providerId'];

    if (status == 'pending' || status == 'accepted' || status == 'processing') {
      return _buildProviderEnRouteWidget(isCustomer, providerId, orderData);
    }
    if (status == 'work_done') {
      return _buildPaymentFlowWidget(isCustomer, isProvider, paymentStatus, finalAmount, orderData);
    }
    if (status == 'completed') {
      return _buildCompletedWidget(isCustomer, providerId);
    }
    
    return Center(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text("Status Pesanan: ${_capitalizeFirstLetter(status)}"),
    ));
  }

  Widget _buildProviderEnRouteWidget(bool isCustomer, String? providerId, Map<String, dynamic> orderData) {
    if (providerId == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Text("Mencari Teknisi...", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20), 
          const CircularProgressIndicator(),
        ]),
      );
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(providerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var providerData = snapshot.data!.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Text(
                isCustomer ? "Teknisi Menuju Lokasi Anda" : "Anda sedang menuju lokasi customer",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(radius: 25, backgroundImage: NetworkImage(providerData['photo_url'] ?? '')),
                title: Text(providerData['nama'] ?? 'Teknisi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: const Text("Rating: 4.5 ★"),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.chat), onPressed: () => Navigator.pushNamed(context, '/chat', arguments: {'receiverUserId': isCustomer ? providerId : orderData['customerId']})),
                  IconButton(icon: const Icon(Icons.call), onPressed: () {}),
                ]),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentFlowWidget(bool isCustomer, bool isProvider, String paymentStatus, num? finalAmount, Map<String, dynamic> orderData) {
    if (_isActionInProgress) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));

    if (isCustomer) {
      if (finalAmount == null) return Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Text("Pekerjaan telah selesai. Menunggu teknisi menetapkan harga akhir...", 
          textAlign: TextAlign.center, 
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue.shade800)
        )
      );
      if (paymentStatus == 'unpaid') {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            Text("Total Tagihan Anda", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Rp ${NumberFormat.decimalPattern('id_ID').format(finalAmount)}", 
              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text("Bayar Sekarang"),
              onPressed: () => _customerPay(finalAmount, orderData['providerId'], orderData['customerId']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            ),
          ]),
        );
      }
      if (paymentStatus == 'paid') return Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Text("Menunggu konfirmasi pembayaran dari teknisi...", 
          style: GoogleFonts.poppins(color: Colors.blue, fontSize: 16)
        )
      );
      if (paymentStatus == 'confirmed') return Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Text("Pembayaran Lunas & Terkonfirmasi!", 
          style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 16)
        )
      );
    }
    
    if (isProvider) {
      if (finalAmount == null) return Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Text("Pekerjaan selesai. Silakan tetapkan harga akhir di halaman detail pesanan.", 
          textAlign: TextAlign.center, 
          style: GoogleFonts.poppins(color: Colors.orange.shade800)
        )
      );
      if (paymentStatus == 'unpaid') return Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Text("Menunggu pembayaran dari pelanggan...", 
          style: GoogleFonts.poppins(color: Colors.orange.shade800)
        )
      );
      if (paymentStatus == 'paid') {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Konfirmasi Pembayaran"),
            onPressed: _providerConfirmPaymentAndCompleteOrder,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
          ),
        );
      }
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCompletedWidget(bool isCustomer, String? providerId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const SizedBox(height: 12),
        Text("Pesanan Selesai!", 
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)
        ),
        const SizedBox(height: 20),
        if (isCustomer && providerId != null)
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/review', arguments: {'orderId': widget.orderId, 'providerId': providerId}), 
            child: const Text("Beri Ulasan")
          ),
      ]),
    );
  }
}