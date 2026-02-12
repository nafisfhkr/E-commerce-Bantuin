import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupPage extends StatefulWidget {
  final String role;

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  
ProfileSetupPage({
    Key? key,
    required this.role,
    this.auth,      // Tambahkan
    this.firestore, // Tambahkan
  }) : super(key: key);  
  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;

@override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _firestore = widget.firestore ?? FirebaseFirestore.instance;  
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Provider specific controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  
  String _selectedCategory = 'Otomotif'; // default untuk provider
  bool _isProcessing = false;

  // Daftar kategori yang tersedia
  final List<String> _availableCategories = [
    'Otomotif', 
    'Elektronik', 
    'Rumah Tangga', 
    'Komputer & Laptop',
    'Handphone',
    'Lainnya'
  ];

  // @override
  // void initState() {
  //   super.initState();
  //   _loadExistingData();
  // }

  Future<void> _loadExistingData() async {
    try {
      final uid = _auth.currentUser?.uid;
      
      if (uid == null) {
        return;
      }
      
      if (widget.role == 'customer') {
        final customerDoc = await _firestore.collection('customers').doc(uid).get();
        
        if (customerDoc.exists && customerDoc.data() != null) {
          final data = customerDoc.data()!;
          setState(() {
            _nameController.text = data['nama'] ?? '';
            _phoneController.text = data['nomor_hp'] ?? '';
            _addressController.text = data['alamat'] ?? '';
          });
        }
      } else {
        final providerDoc = await _firestore.collection('providers').doc(uid).get();
        
        if (providerDoc.exists && providerDoc.data() != null) {
          final data = providerDoc.data()!;
          setState(() {
            _businessNameController.text = data['nama_usaha'] ?? '';
            _descriptionController.text = data['deskripsi'] ?? '';
            _businessAddressController.text = data['alamat_usaha'] ?? '';
            _phoneController.text = data['nomor_hp'] ?? '';
            
            // Validasi nilai kategori dari database
            String kategoriDariDB = data['kategori'] ?? 'Otomotif';
            
            // Cek apakah nilai dari database ada dalam daftar
            if (_availableCategories.contains(kategoriDariDB)) {
              _selectedCategory = kategoriDariDB;
            } else {
              // Jika tidak ada, gunakan nilai default
              _selectedCategory = 'Otomotif';
            }
          });
        }
      }
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Spacer(),
                  Text(
                    'Step 3 of 3',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        widget.role == 'customer' 
                            ? 'Lengkapi Profil Anda' 
                            : 'Lengkapi Profil Usaha Anda',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Silakan lengkapi informasi untuk melanjutkan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Form fields sesuai role
                      if (widget.role == 'customer') ...[
                        // Form untuk customer
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor HP',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Alamat',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ] else ...[
                        // Form untuk provider
                        TextField(
                          controller: _businessNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Usaha',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Kategori Usaha',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _availableCategories.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Usaha',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _businessAddressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Alamat Usaha',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor HP',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                        ),
                      ],
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isProcessing ? null : () => _saveProfile(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.black,
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan & Lanjutkan',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _saveProfile(BuildContext context) async {
    if (_isProcessing) return;
    
    // Validasi input
    if (widget.role == 'customer') {
      if (_nameController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Semua field harus diisi')),
        );
        return;
      }
    } else {
      if (_businessNameController.text.trim().isEmpty ||
          _descriptionController.text.trim().isEmpty ||
          _businessAddressController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Semua field harus diisi')),
        );
        return;
      }
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final uid = _auth.currentUser?.uid;
      
      if (uid == null) {
        throw Exception('User tidak ditemukan');
      }
      
      if (widget.role == 'customer') {
        // Update data customer
        await _firestore.collection('customers').doc(uid).update({
          'nama': _nameController.text.trim(),
          'alamat': _addressController.text.trim(),
          'nomor_hp': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update data provider
        await _firestore.collection('providers').doc(uid).update({
          'nama_usaha': _businessNameController.text.trim(),
          'deskripsi': _descriptionController.text.trim(),
          'kategori': _selectedCategory,
          'alamat_usaha': _businessAddressController.text.trim(),
          'nomor_hp': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Navigasi ke dashboard sesuai role
      _navigateToDashboard();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  void _navigateToDashboard() {
    if (widget.role == 'customer') {
      Navigator.pushReplacementNamed(context, '/dashboard_customer');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard_provider');
    }
  }
}