
import 'package:bantuin/UI/chat/komunikasi.dart';
import 'package:bantuin/UI/penyedia jasa/orderDetail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class ProviderOrderListItem extends StatefulWidget {
  final QueryDocumentSnapshot orderDoc;

  const ProviderOrderListItem({Key? key, required this.orderDoc})
      : super(key: key);

  @override
  _ProviderOrderListItemState createState() => _ProviderOrderListItemState();
}

class _ProviderOrderListItemState extends State<ProviderOrderListItem> {
  Map<String, dynamic>? _customerData;
  bool _isLoading = true;
  double _distance = 0.0;
  double _customerRating = 0.0;
  String _locationDisplay = ''; 

  @override
  void initState() {
    super.initState();
    _fetchUIData();
  }
  
  Future<void> _fetchUIData() async {
    try {
      final orderData = widget.orderDoc.data() as Map<String, dynamic>;
      final customerId = orderData['customerId'];

      if (customerId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('customers').doc(customerId).get(),
        FirebaseFirestore.instance.collection('users').doc(customerId).get(),
      ]);

      final DocumentSnapshot customerDetailDoc = results[0];
      final DocumentSnapshot customerUserDoc = results[1];
      
      String customerProfileAddress = '';

      if (customerDetailDoc.exists) {
        _customerData = customerDetailDoc.data() as Map<String, dynamic>?;
        customerProfileAddress = _customerData?['alamat'] ?? '';
      }
      
      if (customerUserDoc.exists) {
        _customerRating = (customerUserDoc.data() as Map<String, dynamic>?)?['rating'] ?? 0.0;
      }
      
      setState(() {
        _locationDisplay = orderData['orderAddress'] ?? customerProfileAddress;
      });

      if (orderData.containsKey('customerLocation') && orderData['customerLocation'] != null) {
        await _calculateDistance(orderData['customerLocation']);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }

    } catch (e) {
      print("Error fetching UI data: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _calculateDistance(GeoPoint customerGeoPoint) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Layanan lokasi tidak aktif.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      
    
      print('--- KOORDINAT UNTUK PERHITUNGAN JARAK ---');
      print('Lokasi Provider (Anda): Lat=${currentPosition.latitude}, Lng=${currentPosition.longitude}');
      print('Lokasi Pelanggan: Lat=${customerGeoPoint.latitude}, Lng=${customerGeoPoint.longitude}');
      print('-----------------------------------------');

      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        customerGeoPoint.latitude,
        customerGeoPoint.longitude,
      );
      if (mounted) {
        setState(() {
          _distance = distanceInMeters / 1000;
        });
      }
    }
  } catch(e) {
      print("Error calculating distance: $e");
  } finally {
      if(mounted) setState(() => _isLoading = false);
  }
}


  Future<void> _acceptOrder(String orderId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk menerima pesanan.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'providerId': user.uid,
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan diterima.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima pesanan: $e')),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan ditolak.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menolak pesanan: $e')),
        );
      }
    }
  }

  String _capitalizeFirstLetter(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  String _timeAgo(Timestamp timestamp) {
    DateTime now = DateTime.now();
    DateTime date = timestamp.toDate();
    Duration diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).round()} bulan yang lalu';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  String _getServiceAndCategoryDisplay(Map<String, dynamic> details) {
    String type = details['type'] ?? '';
    String service = details['service'] ?? '';

    if (service.isEmpty) {
      service = details['serviceType'] ?? '';
    }

    String mainType = _capitalizeFirstLetter(type);
    String serviceName = _capitalizeFirstLetter(service);

    if (mainType.isNotEmpty && serviceName.isNotEmpty) {
      return '$mainType • $serviceName';
    } else if (serviceName.isNotEmpty) {
      return serviceName;
    }
    return 'Layanan Tidak Diketahui';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3.0,
        child: const SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final orderData = widget.orderDoc.data() as Map<String, dynamic>;
    final String orderId = widget.orderDoc.id;
    final String customerId = orderData['customerId'];
    final String customerName = _customerData?['nama'] ?? 'Pelanggan';
    final String status = orderData['status'] ?? 'pending';
    final Timestamp createdAt = orderData['createdAt'] ?? Timestamp.now();
    final Map<String, dynamic> details = orderData['details'] ?? {};
    final Timestamp? acceptedAt = orderData['acceptedAt'] as Timestamp?;
    final num? finalAmount = orderData['finalAmount'] as num?;
    final String? paymentStatus = orderData['paymentStatus'] as String?;

    final bool isReadyToComplete =
        status == 'work_done' && paymentStatus == 'paid';

    final String serviceAndCategory = _getServiceAndCategoryDisplay(details);
    final String createdTimeAgoText = _timeAgo(createdAt);

    String bottomTimeText = createdTimeAgoText;
    if (status == 'accepted' && acceptedAt != null) {
      bottomTimeText = 'Diterima ${_timeAgo(acceptedAt)}';
    } else if (isReadyToComplete) {
      bottomTimeText = 'Pembayaran Diterima - Konfirmasi Pesanan';
    } else if (status == 'work_done' && paymentStatus == 'confirmed') {
      bottomTimeText = 'Pembayaran Selesai - Selesaikan Pesanan';
    } else if (status == 'work_done' && finalAmount != null) {
      bottomTimeText = 'Menunggu Pembayaran';
    }

    final bool isNewOrder =
        status == 'pending' && orderData['providerId'] == null;
    final bool isAcceptedOrder = status == 'accepted' &&
        orderData['providerId'] == FirebaseAuth.instance.currentUser?.uid;
    final bool isWorkDoneOrder = status == 'work_done' &&
        orderData['providerId'] == FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderOrderDetailScreen(orderId: orderId),
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          serviceAndCategory,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFF8BD00), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _customerRating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jarak : ${_distance.toStringAsFixed(1)} KM',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      
                        if (_locationDisplay.isNotEmpty)
                          const SizedBox(height: 4),
                        if (_locationDisplay.isNotEmpty)
                          Text(
                            'Lokasi : $_locationDisplay',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (finalAmount != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Total : Rp ${NumberFormat('#,###', 'id_ID').format(finalAmount)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isNewOrder)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptOrder(orderId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF192F65),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            minimumSize: const Size(100, 40),
                          ),
                          child: Text(
                            "Terima",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _rejectOrder(orderId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B0000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            minimumSize: const Size(100, 40),
                          ),
                          child: Text(
                            "Tolak",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    )
                  else if (isAcceptedOrder || isWorkDoneOrder)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: isReadyToComplete
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProviderOrderDetailScreen(
                                              orderId: orderId),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReadyToComplete
                                ? const Color(0xFF192959)
                                : const Color(0xFFBBC3C9),
                            foregroundColor:
                                const Color.fromARGB(255, 250, 250, 250),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            minimumSize: const Size(100, 40),
                          ),
                          child: Text(
                            "Selesaikan Pesanan",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 2),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Komunikasi(
                                  receiverUserId: customerId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF192F65),
                            side: const BorderSide(
                                color: Color(0xFF192F65), width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            minimumSize: const Size(100, 40),
                          ),
                          child: Text(
                            "Hubungi Customer",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 10),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _getStatusColor(status), width: 1.0),
                      ),
                      child: Text(
                        _capitalizeFirstLetter(status),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  bottomTimeText,
                  style: GoogleFonts.poppins(
                    color: isReadyToComplete ||
                            (status == 'work_done' &&
                                paymentStatus == 'confirmed')
                        ? const Color(0xFF192F65)
                        : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: isReadyToComplete ||
                            (status == 'work_done' &&
                                paymentStatus == 'confirmed')
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'accepted':
        return Colors.blue.shade700;
      case 'work_done':
        return Colors.purple.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}