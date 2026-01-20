import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class KycStartScreen extends StatefulWidget {
  const KycStartScreen({super.key});

  @override
  State<KycStartScreen> createState() => _KycStartScreenState();
}

class _KycStartScreenState extends State<KycStartScreen> {
  final _formKey = GlobalKey<FormState>();

  String _docType = 'AADHAAR';
  final _docNumberCtrl = TextEditingController();

  File? _docImage;
  bool _loading = false;

  final List<String> _docTypes = ['AADHAAR', 'PASSPORT', 'DRIVING_LICENSE'];

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _docImage = File(picked.path);
    });
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;
    if (_docImage == null) {
      _showError('Please upload document image');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      /// 1️⃣ Upload document
      final ref = FirebaseStorage.instance.ref(
        'kyc/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(
        _docImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final docUrl = await ref.getDownloadURL();

      /// 2️⃣ Save KYC data
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'kyc': {
          'status': 'SUBMITTED',
          'docType': _docType,
          'docNumber': _docNumberCtrl.text.trim(),
          'docImage': docUrl,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC submitted successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start KYC')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// 📄 DOCUMENT TYPE
              DropdownButtonFormField<String>(
                value: _docType,
                items: _docTypes
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _docType = v!),
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),

              const SizedBox(height: 16),

              /// 🔢 DOCUMENT NUMBER
              TextFormField(
                controller: _docNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Document Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),

              /// 📸 DOCUMENT IMAGE
              GestureDetector(
                onTap: _pickDocument,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _docImage == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40),
                              SizedBox(height: 8),
                              Text('Upload Document'),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _docImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              /// 🚀 SUBMIT
              ElevatedButton(
                onPressed: _loading ? null : _submitKyc,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit KYC', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
