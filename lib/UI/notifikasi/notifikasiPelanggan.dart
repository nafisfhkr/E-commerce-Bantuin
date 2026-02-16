
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationCustomerScreen extends StatelessWidget {
  final String orderId;

  const NotificationCustomerScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5), 
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Center(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black, 
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white, width: 2.0),
                ),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      ));
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 10),
                            const Text("Pesanan tidak ditemukan.", style: TextStyle(color: Colors.white)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              child: const Text("Tutup"),
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    var order = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    var details = order['details'] as Map<String, dynamic>? ?? {};
                    String providerId = order['providerId'] ?? '';
                    
                    String serviceType = details['service'] ?? details['serviceType'] ?? 'Layanan';
                    String vehicleType = details['type'] ?? details['vehicleType'] ?? 'Kendaraan/Elektronik';
                    String estimatedPrice = details['estimatedPriceMin']?.toString() ?? order['estimatedPriceMin']?.toString() ?? 'N/A';

                    if (providerId.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Menunggu konfirmasi teknisi...", style: TextStyle(color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                  child: const Text("OK"),
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                              ),
                            ],
                          ),
                        );
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('providers').doc(providerId).get(),
                      builder: (context, providerSnapshot) {
                        if (providerSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(30.0),
                            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          ));
                        }
                        
                        String providerName = 'Teknisi';
                        if (providerSnapshot.hasData && providerSnapshot.data!.exists) {
                           var providerData = providerSnapshot.data!.data() as Map<String, dynamic>;
                           providerName = providerData['nama'] ?? 'Teknisi';
                        }

                      
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Pesanan Diterima!", style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                   
                                    Icon(Icons.build_circle_outlined, color: Colors.white, size: 28),
                                    SizedBox(width: 8),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(serviceType, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(vehicleType, style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ]),
                                  ]),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                     Text('Rp.$estimatedPrice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ]),
                                ],
                              ),
                              SizedBox(height: 25),
                             
                              Row(
                                children: [
                                  Icon(Icons.person_pin_circle_outlined, color: Colors.blueAccent, size: 40),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(providerName, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Akan segera menuju lokasimu.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    ]),
                                  ),
                                ],
                              ),
                              SizedBox(height: 25),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                                    onPressed: () {
                                      Navigator.pop(context); 
                                     Navigator.pushNamed(context, '/chat', arguments: {'receiverUserId': providerId});
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.call_outlined, color: Colors.white, size: 28),
                                    onPressed: () {
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              ElevatedButton(
                                child: Text("Tutup"),
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
                              )
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}