import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bantuin/Logic/services/pelanggan_service.dart';

class CustomerProfileEditScreen extends StatefulWidget {
  const CustomerProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<CustomerProfileEditScreen> createState() => _CustomerProfileEditScreenState();
}

class _CustomerProfileEditScreenState extends State<CustomerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();
  User? _currentUser;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();
  
  String _email = '';
  String? _photoUrl;
  File? _imageFile;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      _email = _currentUser!.email ?? '';
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        _namaController.text = userDoc.get('nama') ?? '';
      }

      DocumentSnapshot customerDoc = await _customerService.getCustomerData(_currentUser!.uid);
      if (customerDoc.exists) {
        var data = customerDoc.data() as Map<String, dynamic>;
        _namaController.text = data['nama'] ?? _namaController.text;
        _alamatController.text = data['alamat'] ?? '';
        _nomorHpController.text = data['nomor_hp'] ?? '';
        _photoUrl = data['photo_url'];
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
        _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar');
    }
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    try {
      String fileName = 'profile_${_currentUser!.uid}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('customer_profiles/${_currentUser!.uid}/$fileName');
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      setState(() => _photoUrl = url);
      _showSnackBar('Foto berhasil diunggah!');
    } catch (e) {
      _showSnackBar('Gagal mengunggah foto');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> updateData = {
        'nama': _namaController.text.trim(),
        'alamat': _alamatController.text.trim(),
        'nomor_hp': _nomorHpController.text.trim(),
        'photo_url': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _customerService.updateCustomerProfile(_currentUser!.uid, updateData);
      
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'nama': _namaController.text.trim(),
      });

      _showSnackBar('Profil berhasil disimpan!', isError: false);
    } catch (e) {
      _showSnackBar('Gagal menyimpan profil');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profil', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF192F65),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 30),
                    _buildReadOnlyField('Email', _email, Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildTextField(_namaController, 'Nama Lengkap', Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(_nomorHpController, 'Nomor HP', Icons.phone_outlined, isPhone: true),
                    const SizedBox(height: 16),
                    _buildTextField(_alamatController, 'Alamat', Icons.location_on_outlined, maxLines: 3),
                    const SizedBox(height: 40),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF192F65),
              child: IconButton(
                icon: _isUploadingImage 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => val == null || val.isEmpty ? '$label tidak boleh kosong' : null,
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isSaving 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}