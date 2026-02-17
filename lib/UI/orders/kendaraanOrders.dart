import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bantuin/Logic/services/order_service.dart';

class VehicleServicePage extends StatefulWidget {
  const VehicleServicePage({Key? key}) : super(key: key);

  @override
  State<VehicleServicePage> createState() => _VehicleServicePageState();
}

class _VehicleServicePageState extends State<VehicleServicePage> {
  final OrderService _orderService = OrderService();
  String selectedVehicleType = 'mobil';
  String selectedCategory = 'sedan';
  String selectedService = 'ban';
  String description = '';
  bool _isLoading = false;

  TextEditingController lokasiController = TextEditingController();
  Position? _currentPosition;

  final Map<String, Map<String, dynamic>> carCategories = {
    'sedan': {
      'label': 'Sedan',
      'image': 'assets/images/vehicles/mobil/sedan.png',
    },
    'family': {
      'label': 'Family Car',
      'image': 'assets/images/vehicles/mobil/family.png',
    },
    'pickup': {
      'label': 'Mobil Bak',
      'image': 'assets/images/vehicles/mobil/bak.png',
    },
    'sport': {
      'label': 'Sport',
      'image': 'assets/images/vehicles/mobil/sport.png',
    },
  };

  final Map<String, Map<String, dynamic>> motorcycleCategories = {
    'matic': {
      'label': 'Matic',
      'image': 'assets/images/vehicles/motor/matic.png',
    },
    'bebek': {
      'label': 'Bebek',
      'image': 'assets/images/vehicles/motor/bebek.png',
    },
    'cruiser': {
      'label': 'Cruiser',
      'image': 'assets/images/vehicles/motor/cruiser.png',
    },
    'trail': {
      'label': 'Trail',
      'image': 'assets/images/vehicles/motor/Trail.png',
    },
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted)
        setState(() => lokasiController.text = 'Lokasi saat ini terdeteksi');
    } catch (e) {
      if (mounted)
        setState(() => lokasiController.text = 'Gagal mendapatkan lokasi');
    }
  }

  Future<void> _createOrder() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        description.isEmpty ||
        lokasiController.text.isEmpty ||
        _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data dan lokasi Anda')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> orderData = {
        'customerId': user.uid,
        'providerId': null,
        'orderType': 'vehicle',
        'details': {
          'category': 'Kendaraan',
          'type': selectedVehicleType,
          'service': selectedService,
          'categoryType': selectedCategory,
        },
        'description': description,
        'orderAddress': lokasiController.text.trim(),
        'customerLocation': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final orderRef = await _orderService.createNewOrder(orderData);

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/peta',
        arguments: {'orderId': orderRef.id},
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F1F0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Lokasi Anda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: TextField(
                    controller: lokasiController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan alamat lengkap',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                const Text(
                  'Jelaskan Kendala',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tips: Jelaskan kerusakan secara rinci (cth: bunyi mesin, asap, error code) agar AI dapat mengestimasi harga dengan akurat.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: TextField(
                    onChanged: (text) {
                      setState(() {
                        description = text;
                      });
                    },
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Cth: Gatau kenapa tiba2 aja mogok',
                      filled: true,
                      fillColor: const Color.fromARGB(255, 255, 255, 255),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pilih Kendaraan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildVehicleTypeOption(
                      'Mobil',
                      'assets/images/mobil.png',
                      'mobil',
                    ),
                    const SizedBox(width: 16),
                    _buildVehicleTypeOption(
                      'Motor',
                      'assets/images/vestic.png',
                      'motor',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDynamicCategorySection(),
                const SizedBox(height: 24),
                const Text(
                  'Pilih Layanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildServiceOption('Oli', 'assets/images/oli.png', 'oli'),
                    _buildServiceOption('Ban', 'assets/images/ban.png', 'ban'),
                    _buildServiceOption(
                      'Mogok',
                      'assets/images/mogok.png',
                      'mogok',
                    ),
                    _buildServiceOption('AC', 'assets/images/ac.png', 'ac'),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2B66),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Lanjut',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicCategorySection() {
    final categoriesToShow =
        selectedVehicleType == 'mobil' ? carCategories : motorcycleCategories;

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          String key = categoriesToShow.keys.elementAt(index);
          Map<String, dynamic> details = categoriesToShow[key]!;

          return Container(
            width: 110,
            margin: EdgeInsets.only(
              right: index == categoriesToShow.length - 1 ? 0 : 12,
            ),
            child:
                selectedVehicleType == 'mobil'
                    ? _buildCarCategoryOptionPortrait(
                      details['label']!,
                      details['image']!,
                      key,
                    )
                    : _buildMotorcycleCategoryOptionPortrait(
                      details['label']!,
                      details['image']!,
                      key,
                    ),
          );
        },
      ),
    );
  }

  Widget _buildCarCategoryOptionPortrait(
    String label,
    String imagePath,
    String value,
  ) {
    bool isSelected = selectedCategory == value;
    final offset = isSelected ? Offset.zero : const Offset(0.5, 0);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 160,
        width: 110,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? const Color(0xFF1A2B66).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1A2B66) : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: AnimatedSlide(
                offset: offset,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotorcycleCategoryOptionPortrait(
    String label,
    String imagePath,
    String value,
  ) {
    bool isSelected = selectedCategory == value;
    final offset = isSelected ? Offset.zero : const Offset(0.5, 0);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 160,
        width: 110,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? const Color(0xFF1A2B66).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 12, right: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1A2B66) : Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: AnimatedSlide(
                offset: offset,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeOption(String label, String imagePath, String value) {
    bool isSelected = selectedVehicleType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedVehicleType = value;
            if (value == 'mobil') {
              selectedCategory = carCategories.keys.first;
            } else {
              selectedCategory = motorcycleCategories.keys.first;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300,
              width: isSelected ? 5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isSelected
                        ? const Color(0xFF1A2B66).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 14,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF1A2B66) : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 160,
                height: 100,
                child: AnimatedScale(
                  scale: isSelected ? 1.50 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarCategoryOption(String label, String imagePath, String value) {
    bool isSelected = selectedCategory == value;
    final offset = isSelected ? Offset.zero : const Offset(0.3, 0);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 120,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300,
            width: isSelected ? 3.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1A2B66) : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: AnimatedSlide(
                offset: offset,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotorcycleCategoryOption(
    String label,
    String imagePath,
    String value,
  ) {
    bool isSelected = selectedCategory == value;
    final double initialHorizontalAlignment = 2;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 150,
        width: isSelected ? 100 : 110,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1A2B66) : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: AnimatedAlign(
                alignment:
                    isSelected
                        ? Alignment.center
                        : Alignment(initialHorizontalAlignment, 0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(String label, String imagePath, String value) {
    bool isSelected = selectedService == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedService = value;
          });
        },
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
            border: Border.all(
              color: isSelected ? const Color(0xFF1A2B66) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2B66),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.none,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    cacheWidth: 108,
                    cacheHeight: 108,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
