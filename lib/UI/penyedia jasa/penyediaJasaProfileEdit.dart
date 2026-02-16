
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({Key? key}) : super(key: key);

  @override
  _ProviderProfileEditScreenState createState() => _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends State<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentUser = FirebaseAuth.instance.currentUser;

  final _namaUsahaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatUsahaController = TextEditingController();
  final _nomorHpController = TextEditingController();

  String? _photoUrl;
  File? _imageFile;
  bool _isElectronic = false;
  bool _isVehicle = false;
  String _verificationStatus = 'pending';
  num _rating = 0;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('providers').doc(_currentUser!.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _namaUsahaController.text = data['nama_usaha'] ?? '';
        _deskripsiController.text = data['deskripsi'] ?? '';
        _alamatUsahaController.text = data['alamat_usaha'] ?? '';
        _nomorHpController.text = data['nomor_hp'] ?? '';
        _photoUrl = data['photo_url'];
        _verificationStatus = data['status_verifikasi'] ?? 'pending';
        _rating = data['rating'] ?? 0;
        
        final specializations = data['specializations'] as Map<String, dynamic>? ?? {};
        _isElectronic = specializations['electronic'] ?? false;
        _isVehicle = specializations['vehicle'] ?? false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat data: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null && mounted) {
      setState(() { _isSaving = true; }); 
      _imageFile = File(pickedFile.path);

      try {
        final fileName = 'profile_${_currentUser!.uid}.jpg';
        final ref = FirebaseStorage.instance.ref().child('provider_profile_pictures/${_currentUser!.uid}/$fileName');
        await ref.putFile(_imageFile!);
        final downloadUrl = await ref.getDownloadURL();
        
        setState(() { _photoUrl = downloadUrl; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Foto profil berhasil diunggah!"), backgroundColor: Colors.green));

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengunggah foto: $e"), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() { _isSaving = false; });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_currentUser == null) return;

    setState(() { _isSaving = true; });

    try {
      final dataToSave = {
        'nama_usaha': _namaUsahaController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'alamat_usaha': _alamatUsahaController.text.trim(),
        'nomor_hp': _nomorHpController.text.trim(),
        'photo_url': _photoUrl ?? '',
        'specializations': {
          'electronic': _isElectronic,
          'vehicle': _isVehicle,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('providers').doc(_currentUser!.uid).set(dataToSave, SetOptions(merge: true));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profil berhasil diperbarui!"), backgroundColor: Colors.green));

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan profil: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  void dispose() {
    _namaUsahaController.dispose();
    _deskripsiController.dispose();
    _alamatUsahaController.dispose();
    _nomorHpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Atur Profil Jasa", style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF192F6A),
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) : null) as ImageProvider?,
                            child: (_imageFile == null && (_photoUrl == null || _photoUrl!.isEmpty))
                                ? Icon(Icons.store, size: 70, color: Colors.grey.shade500)
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Material(
                              color: Theme.of(context).primaryColor, shape: CircleBorder(),
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _pickAndUploadImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildTextFormField(controller: _namaUsahaController, label: 'Nama Usaha/Toko', icon: Icons.storefront),
                    SizedBox(height: 16),
                    _buildTextFormField(controller: _deskripsiController, label: 'Deskripsi Singkat Usaha', icon: Icons.description_outlined, maxLines: 3),
                    SizedBox(height: 16),
                    _buildTextFormField(controller: _alamatUsahaController, label: 'Alamat Usaha', icon: Icons.location_on_outlined, maxLines: 2),
                    SizedBox(height: 16),
                    _buildTextFormField(controller: _nomorHpController, label: 'Nomor HP (WhatsApp)', icon: Icons.phone, keyboardType: TextInputType.phone),
                    SizedBox(height: 24),
                    Text("Spesialisasi Layanan", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    CheckboxListTile(
                      title: Text("Elektronik"),
                      value: _isElectronic,
                      onChanged: (bool? value) { setState(() { _isElectronic = value ?? false; }); },
                    ),
                    CheckboxListTile(
                      title: Text("Kendaraan"),
                      value: _isVehicle,
                      onChanged: (bool? value) { setState(() { _isVehicle = value ?? false; }); },
                    ),
                    SizedBox(height: 24),
                    _buildReadOnlyInfo("Status Verifikasi", _verificationStatus[0].toUpperCase() + _verificationStatus.substring(1), _verificationStatus == 'verified' ? Colors.green : Colors.orange),
                    _buildReadOnlyInfo("Rating Anda", "${_rating.toStringAsFixed(1)} ★", Colors.amber.shade700),
                    SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: _isSaving ? SizedBox.shrink() : Icon(Icons.save),
                      label: _isSaving ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : Text('Simpan Perubahan'),
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  Widget _buildTextFormField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true, fillColor: Colors.white,
      ),
      validator: (value) => (value == null || value.isEmpty) ? '$label tidak boleh kosong' : null,
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        trailing: Text(value, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}