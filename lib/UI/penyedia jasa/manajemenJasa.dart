
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ServiceCategory { kendaraan, elektronik }

class ManajemenLayananPage extends StatefulWidget {
  const ManajemenLayananPage({Key? key}) : super(key: key);

  @override
  _ManajemenLayananPageState createState() => _ManajemenLayananPageState();
}

class _ManajemenLayananPageState extends State<ManajemenLayananPage> {
  ServiceCategory _selectedCategory = ServiceCategory.kendaraan;
  bool _isLoading = true;

  
  Map<String, bool> _vehicleTypes = {'Mobil': false, 'Motor': false};
  Map<String, bool> _electronicTypes = {'Rumah Tangga': false, 'Kantor': false};

  Map<String, bool> _vehicleServices = {
    'Ganti Oli': false, 'Servis ringan': false, 'Ganti kampas rem': false,
    'Perbaikan dan Penggantian Ban': false, 'Pemasangan Aksesori Kendaraan': false,
    'Perawatan Rantai Motor': false, 'Servis Aki': false,
    'Pengecekan dan Perbaikan Sistem Suspensi': false,
  };

  Map<String, bool> _electronicServices = {
    'Perbaikan Kulkas & Freezer': false, 'Perbaikan Mesin Cuci': false,
    'Instalasi & Perbaikan TV': false, 'Perbaikan Pompa Air & Pemanas Air': false,
    'Servis Peralatan Dapur': false, 'Servis AC': false,
    'Servis Komputer & Laptop': false, 'Instalasi & Troubleshooting Jaringan': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSelectionsFromFirestore();
  }

  
  Future<void> _loadSelectionsFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    
    if (mounted) setState(() => _isLoading = true);

    try {
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(user.uid)
          .get();

      if (providerDoc.exists) {
        final data = providerDoc.data() as Map<String, dynamic>?;
        final activeServices = data?['activeServices'] as Map<String, dynamic>? ?? {};

        final savedVehicleTypes = activeServices['vehicle_types'] as Map<String, dynamic>? ?? {};
        final savedElectronicTypes = activeServices['electronic_types'] as Map<String, dynamic>? ?? {};
        final savedVehicleServices = activeServices['vehicle_services'] as Map<String, dynamic>? ?? {};
        final savedElectronicServices = activeServices['electronic_services'] as Map<String, dynamic>? ?? {};

        
        Map<String, bool> newVehicleTypes = {
          for (var key in _vehicleTypes.keys) key: savedVehicleTypes[key] ?? false
        };

        Map<String, bool> newElectronicTypes = {
          for (var key in _electronicTypes.keys) key: savedElectronicTypes[key] ?? false
        };

        Map<String, bool> newVehicleServices = {
          for (var key in _vehicleServices.keys) key: savedVehicleServices[key] ?? false
        };
        
        Map<String, bool> newElectronicServices = {
          for (var key in _electronicServices.keys) key: savedElectronicServices[key] ?? false
        };
        
       
        if (mounted) {
          setState(() {
            _vehicleTypes = newVehicleTypes;
            _electronicTypes = newElectronicTypes;
            _vehicleServices = newVehicleServices;
            _electronicServices = newElectronicServices;
          });
        }
      }
    } catch (e) {
      print("Gagal memuat data dari Firestore: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
          );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelectionsToFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final Map<String, dynamic> dataToSave = {
      'activeServices': {
        'vehicle_types': _vehicleTypes,
        'electronic_types': _electronicTypes,
        'vehicle_services': _vehicleServices,
        'electronic_services': _electronicServices,
      }
    };

    try {
      await FirebaseFirestore.instance.collection('providers').doc(user.uid).set(dataToSave, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilihan layanan berhasil disimpan!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Manajemen Layanan', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryToggle(),
                  const SizedBox(height: 24),
                  if (_selectedCategory == ServiceCategory.kendaraan)
                    _buildVehicleContent()
                  else
                    _buildElectronicContent(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCategoryToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton('Kendaraan', ServiceCategory.kendaraan)),
          Expanded(child: _buildToggleButton('Elektronik', ServiceCategory.elektronik)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, ServiceCategory category) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF192F65) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Kendaraan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTypeCard(
              label: 'Mobil',
              imagePath: 'assets/images/vehicles/mobil/sport.png', 
              isSelected: _vehicleTypes['Mobil'] ?? false,
              onTap: () {
                setState(() { _vehicleTypes['Mobil'] = !(_vehicleTypes['Mobil'] ?? false); });
                _saveSelectionsToFirestore();
              },
            ),
            const SizedBox(width: 16),
            _buildTypeCard(
              label: 'Motor',
              imagePath: 'assets/images/vestic.png', 
              isSelected: _vehicleTypes['Motor'] ?? false,
              onTap: () {
                setState(() { _vehicleTypes['Motor'] = !(_vehicleTypes['Motor'] ?? false); });
                _saveSelectionsToFirestore();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Pilih Beberapa Layanan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._vehicleServices.keys.map((serviceName) {
          return _buildCheckboxListTile(
            title: serviceName,
            value: _vehicleServices[serviceName]!,
            onChanged: (val) {
              setState(() => _vehicleServices[serviceName] = val!);
              _saveSelectionsToFirestore();
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildElectronicContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Jenis Elektronik', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildTypeCard(
              label: 'Rumah Tangga',
              imagePath: 'assets/images/elektronik/rumah tangga.png', 
              isSelected: _electronicTypes['Rumah Tangga'] ?? false,
              onTap: () {
                setState(() { _electronicTypes['Rumah Tangga'] = !(_electronicTypes['Rumah Tangga'] ?? false); });
                _saveSelectionsToFirestore();
              },
            ),
            const SizedBox(width: 16),
            _buildTypeCard(
              label: 'Kantor',
              imagePath: 'assets/images/elektronik/kantor.png', 
              isSelected: _electronicTypes['Kantor'] ?? false,
              onTap: () {
                setState(() { _electronicTypes['Kantor'] = !(_electronicTypes['Kantor'] ?? false); });
                _saveSelectionsToFirestore(); 
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Pilih Beberapa Layanan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._electronicServices.keys.map((serviceName) {
          return _buildCheckboxListTile(
            title: serviceName,
            value: _electronicServices[serviceName]!,
            onChanged: (val) {
              setState(() => _electronicServices[serviceName] = val!);
              _saveSelectionsToFirestore();
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTypeCard({ required String label, required String imagePath, required bool isSelected, required VoidCallback onTap }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF1A2B66) : Colors.grey.shade300, width: isSelected ? 2 : 1),
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
              Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 80,
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxListTile({ required String title, required bool value, required ValueChanged<bool?> onChanged }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        secondary: const Icon(Icons.build_circle_outlined, color: Color(0xFF192F65)),
        activeColor: const Color(0xFF1A2B65),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}