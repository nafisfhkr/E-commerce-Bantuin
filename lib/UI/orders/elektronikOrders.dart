import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';


import 'package:bantuin/UI/maps/peta_driver.dart';
import 'package:bantuin/Logic/services/order_service.dart';

class ElectronicServicePage extends StatefulWidget {
  const ElectronicServicePage({Key? key}) : super(key: key);

  @override
  State<ElectronicServicePage> createState() => _ElectronicServicePageState();
}

class _ElectronicServicePageState extends State<ElectronicServicePage> {
  final OrderService _orderService = OrderService();
  String selectedElectronicType = 'household';
  String selectedCategory = 'pendingin_ruangan';
  String selectedService = 'perbaikan_layar';
  String description = '';
  bool _isLoading = false;

  TextEditingController lokasiController = TextEditingController();
  Position? _currentPosition;

  // ... (Gunakan data mainElectronicCategories dan electronicServices asli) ...
  final Map<String, Map<String, dynamic>> mainElectronicCategories = {
    'household': {
      'label': 'Rumah Tangga',
      'image': 'assets/images/elektronik/rumah tangga.png',
      'subcategories': {
        'pendingin_ruangan': {
          'label': 'Pendingin Ruangan',
          'image': 'assets/images/elektronik/rumahtangga/pendingin.png',
        },
        'pembersih': {
          'label': 'Pembersih',
          'image': 'assets/images/elektronik/rumahtangga/pembersih.png',
        },
        'dapur': {
          'label': 'Dapur',
          'image': 'assets/images/elektronik/rumahtangga/dapur.png',
        },
      },
    },
    'office': {
      'label': 'Kantor',
      'image': 'assets/images/elektronik/kantor.png',
      'subcategories': {
        'komputer': {
          'label': 'Komputer & Aksesoris',
          'image': 'assets/images/elektronik/kantor/komputer dan aksesoris.png',
        },
        'printer': {
          'label': 'Printer & Scanner',
          'image': 'assets/images/elektronik/kantor/hp dan aksesoris.png',
        },
        'proyektor': {
          'label': 'Proyektor',
          'image': 'assets/images/elektronik/kantor/audio dan visual.png',
        },
        'lain_lain_kantor': {
          'label': 'Lain-lain',
          'image': 'assets/images/elektronik/kantor/lain-lain.png',
        },
      },
    },
  };

  final Map<String, Map<String, dynamic>> electronicServices = {
    'perbaikan_layar': {
      'label': 'Perbaikan Layar',
      'image': 'assets/images/elektronik/layanan/perbaikan layar.png',
    },
    'perbaikan_mesin': {
      'label': 'Perbaikan Mesin',
      'image': 'assets/images/elektronik/layanan/perbaikan mesin.png',
    },
    'instalasi_baru': {
      'label': 'Instalasi Baru',
      'image': 'assets/images/elektronik/layanan/instalasi.png',
    },
    'perawatan': {
      'label': 'Perawatan',
      'image': 'assets/images/elektronik/layanan/perawatan.png',
    },
    'lain_lain_service': {
      'label': 'Lain-lain',
      'image': 'assets/images/elektronik/layanan/lain-lain.png',
    },
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _updateSelectedCategoryBasedOnType();
  }

  void _updateSelectedCategoryBasedOnType() {
    if (mainElectronicCategories.containsKey(selectedElectronicType)) {
      final typeData = mainElectronicCategories[selectedElectronicType]!;
      final subCategories = typeData['subcategories'] as Map<String, dynamic>;
      if (subCategories.isNotEmpty) {
        selectedCategory = subCategories.keys.first;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi tidak aktif')),
      );
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak')),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak secara permanen')),
      );
      return;
    }
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          lokasiController.text = 'Lokasi saat ini terdeteksi';
        });
      }
    } catch (e) {
      print("Gagal mendapatkan lokasi: $e");
      if (mounted) {
        setState(() {
          lokasiController.text = 'Gagal mendapatkan lokasi';
        });
      }
    }
  }

  Future<void> _createOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login terlebih dahulu')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (description.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan jelaskan kendala elektronik Anda'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (lokasiController.text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan masukkan lokasi Anda')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (_currentPosition == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan lokasi Anda')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final String imagePath =
          mainElectronicCategories[selectedElectronicType]?['subcategories']?[selectedCategory]?['image'] ??
          'assets/images/elektronik/layanan/lain-lain.png';

      Map<String, dynamic> details = {
        'category': 'Elektronik',
        'electronicType': selectedElectronicType,
        'electronicModel': selectedCategory,
        'service': selectedService,
        'itemImageUrl': imagePath,
      };

      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'customerId': user.uid,
        'providerId': null,
        'orderType': 'electronic',
        'details': details,
        'description': description,
        'orderAddress': lokasiController.text.trim(),
        'customerLocation': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        'providerLocation': null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'distance': null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibuat')),
      );

      Navigator.pushNamed(
        context,
        '/peta',
        arguments: {'orderId': orderRef.id},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pesanan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk mengkapitalisasi huruf pertama setiap kata
  String _capitalizeEachWord(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    // ... (Tampilan UI tetap sama persis dengan kode asli Anda) ...
    final currentSubCategories =
        mainElectronicCategories[selectedElectronicType]?['subcategories'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F1F0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pesanan Elektronik',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
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
                const SizedBox(height: 8),
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
                      hintText: 'Cth: Tiba - tiba matot saat main game',
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
                  'Pilih Jenis Elektronik',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mainElectronicCategories.keys.length,
                    itemBuilder: (context, index) {
                      String key = mainElectronicCategories.keys.elementAt(index);
                      Map<String, dynamic> typeData = mainElectronicCategories[key]!;
                      return Container(
                        width: 140,
                        margin: EdgeInsets.only(
                          right: index == mainElectronicCategories.keys.length - 1 ? 0 : 12,
                        ),
                        child: _buildElectronicTypeOption(
                          typeData['label']!,
                          typeData['image']!,
                          key,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDynamicElectronicCategorySection(),
                const SizedBox(height: 24),
                const Text(
                  'Pilih Layanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: electronicServices.keys.length,
                    itemBuilder: (context, index) {
                      String key = electronicServices.keys.elementAt(index);
                      Map<String, dynamic> details = electronicServices[key]!;
                      return Container(
                        width: 80,
                        margin: EdgeInsets.only(
                          right: index == electronicServices.keys.length - 1 ? 0 : 12,
                        ),
                        child: _buildServiceOption(
                          details['label']!,
                          details['image']!,
                          key,
                        ),
                      );
                    },
                  ),
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
                    child: _isLoading
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

  Widget _buildElectronicTypeOption(
    String label,
    String imagePath,
    String value,
  ) {
    bool isSelected = selectedElectronicType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedElectronicType = value;
          _updateSelectedCategoryBasedOnType();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        height: 160,
        width: 140,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300,
            width: isSelected ? 5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0xFF1A2B66).withOpacity(0.3) : Colors.grey.withOpacity(0.1),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1A2B66) : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicElectronicCategorySection() {
    final categoriesToShow = mainElectronicCategories[selectedElectronicType]?['subcategories'] as Map<String, dynamic>? ?? {};

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
            child: _buildElectronicCategoryOption(
              details['label']!,
              details['image']!,
              key,
            ),
          );
        },
      ),
    );
  }

  Widget _buildElectronicCategoryOption(
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
              color: isSelected ? const Color(0xFF1A2B66).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
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
                style: GoogleFonts.poppins(
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

  Widget _buildServiceOption(String label, String imagePath, String value) {
    bool isSelected = selectedService == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedService = value;
        });
      },
      child: Container(
        height: 120,
        width: 100,
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
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
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
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}