import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController firstNameCtrl;
  late TextEditingController lastNameCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;

  late TextEditingController address1Ctrl;
  late TextEditingController address2Ctrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController countryCtrl;
  late TextEditingController pincodeCtrl;

  File? _selectedImage;
  String? _photoUrl;
  double _uploadProgress = 0.0;
  bool _uploadingPhoto = false;
  bool _pincodeLoading = false;
  bool _locationLoading = false;

  bool loading = false;

  final Uint8List kTransparentImage = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
  ]);
  @override
  void initState() {
    super.initState();

    final profile = ref.read(userProfileProvider).value!;
    _photoUrl = profile['photoUrl'];

    firstNameCtrl = TextEditingController(text: profile['firstName'] ?? '');
    lastNameCtrl = TextEditingController(text: profile['lastName'] ?? '');
    phoneCtrl = TextEditingController(text: profile['phone'] ?? '');
    emailCtrl = TextEditingController(text: profile['email'] ?? '');

    final address = profile['address'] ?? {};

    address1Ctrl = TextEditingController(text: address['line1'] ?? '');
    address2Ctrl = TextEditingController(text: address['line2'] ?? '');
    cityCtrl = TextEditingController(text: address['city'] ?? '');
    stateCtrl = TextEditingController(text: address['state'] ?? '');
    countryCtrl = TextEditingController(text: address['country'] ?? '');
    pincodeCtrl = TextEditingController(text: address['pincode'] ?? '');
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();

    address1Ctrl.dispose();
    address2Ctrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    countryCtrl.dispose();
    pincodeCtrl.dispose();

    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              _ImageSourceTile(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              _ImageSourceTile(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: source, imageQuality: 90);

    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,

      uiSettings: [
        /// ANDROID
        AndroidUiSettings(
          toolbarTitle: 'Edit Photo',
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Colors.white,

          hideBottomControls: false, // 🔥 must be FALSE
          lockAspectRatio: false,
          showCropGrid: true,

          activeControlsWidgetColor: Theme.of(context).colorScheme.primary,

          statusBarColor: Theme.of(context).colorScheme.primary,

          backgroundColor: Colors.black,
        ),

        /// IOS
        IOSUiSettings(
          title: 'Edit Photo',
          aspectRatioLockEnabled: false,
          resetAspectRatioEnabled: true,

          /// 🔥 ROTATE & FLIP
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
          hidesNavigationBar: false,
        ),
      ],
    );

    if (cropped == null) return;

    setState(() {
      _selectedImage = File(cropped.path);
    });
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_selectedImage == null) return _photoUrl;

    final storageRef = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');

    setState(() {
      _uploadingPhoto = true;
      _uploadProgress = 0;
    });

    final uploadTask = storageRef.putFile(
      _selectedImage!,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    uploadTask.snapshotEvents.listen((event) {
      if (!mounted) return;

      if (event.totalBytes > 0) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      } else {
        // fallback: indeterminate
        setState(() {
          _uploadProgress = 0;
        });
      }
    });

    final snapshot = await uploadTask;

    if (!mounted) return _photoUrl;

    setState(() {
      _uploadingPhoto = false;
      _uploadProgress = 0;
    });

    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _fetchAddressFromGPS() async {
    try {
      setState(() => _locationLoading = true);

      // 1️⃣ Check service
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location services are disabled';
      }

      // 2️⃣ Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied';
      }

      // 3️⃣ Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4️⃣ Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return;

      final place = placemarks.first;

      setState(() {
        address1Ctrl.text = '${place.street ?? ''}, ${place.subLocality ?? ''}'
            .trim();

        cityCtrl.text = place.locality ?? '';
        stateCtrl.text = place.administrativeArea ?? '';
        countryCtrl.text = place.country ?? 'India';
        pincodeCtrl.text = place.postalCode ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _locationLoading = false);
    }
  }

  Future<void> _fetchCityStateFromPincode(String pincode) async {
    if (pincode.length != 6) return;

    setState(() => _pincodeLoading = true);

    try {
      final res = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
      );

      final data = jsonDecode(res.body);

      if (data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
        final postOffice = data[0]['PostOffice'][0];

        setState(() {
          cityCtrl.text = postOffice['District'] ?? '';
          stateCtrl.text = postOffice['State'] ?? '';
          countryCtrl.text = 'India';
        });
      }
    } catch (_) {
      // silent fail (don’t disturb user)
    } finally {
      if (mounted) {
        setState(() => _pincodeLoading = false);
      }
    }
  }

  void _showSaveSuccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.35), blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Saved successfully',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final photoUrl = await _uploadPhoto(uid);

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'firstName': firstNameCtrl.text.trim(),
      'lastName': lastNameCtrl.text.trim(),
      'photoUrl': photoUrl,
      'address': {
        'line1': address1Ctrl.text.trim(),
        'line2': address2Ctrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'country': countryCtrl.text.trim(),
        'pincode': pincodeCtrl.text.trim(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ref.invalidate(userProfileProvider);

    _showSaveSuccess(context);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.pop(context);
    });

    // if (mounted) {
    //   Navigator.pop(context);
    //}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (loading || _uploadingPhoto) ? null : _save,
                child: loading || _uploadingPhoto
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// 🖼 PROFILE PHOTO
                GestureDetector(
                  onTap: _chooseImageSource,
                  child: Stack(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 92,
                              height: 92,
                              child: _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: _photoUrl!,
                                      fit: BoxFit.cover,
                                      fadeInDuration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      placeholder: (context, url) => Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _InitialsAvatar(
                                            firstName: firstNameCtrl.text,
                                            lastName: lastNameCtrl.text,
                                          ),
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          _InitialsAvatar(
                                            firstName: firstNameCtrl.text,
                                            lastName: lastNameCtrl.text,
                                          ),
                                    )
                                  : _InitialsAvatar(
                                      firstName: firstNameCtrl.text,
                                      lastName: lastNameCtrl.text,
                                    ),
                            ),
                          ),

                          /// 🔄 UPLOAD PROGRESS RING
                          if (_uploadingPhoto)
                            SizedBox(
                              width: 96,
                              height: 96,
                              child: CircularProgressIndicator(
                                value: _uploadProgress > 0
                                    ? _uploadProgress
                                    : null,
                                strokeWidth: 4,
                                backgroundColor: Colors.white,
                                valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      /// ✏️ EDIT ICON
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🧑 First Name
                TextFormField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 16),

                /// 🧑 Last Name
                TextFormField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 24),

                /// 📱 Phone (Disabled)
                TextFormField(
                  controller: phoneCtrl,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: const Icon(Icons.phone),
                    suffixIcon: const Icon(Icons.verified, color: Colors.green),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 📧 Email (Disabled)
                TextFormField(
                  controller: emailCtrl,
                  enabled: true,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// ℹ️ Info hint
                Text(
                  'Phone number and email cannot be changed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                /// 📍 ADDRESS SECTION
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Address Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: address1Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: address2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2 (Optional)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: _locationLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                    onPressed: _locationLoading ? null : _fetchAddressFromGPS,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                    suffixIcon: _pincodeLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    if (val.length == 6) {
                      _fetchCityStateFromPincode(val);
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cityCtrl,
                        enabled: true, // 🔒 auto-filled
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: stateCtrl,
                        enabled: true, // 🔒 auto-filled
                        decoration: const InputDecoration(
                          labelText: 'State',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: countryCtrl,
                  enabled: true, // 🔒 auto-filled
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.public),
                  ),
                ),

                //const Spacer(),
                // const SizedBox(height: 32),

                // /// 💾 Save Button
                // SizedBox(
                //   width: double.infinity,
                //   height: 52,
                //   child: ElevatedButton(
                //     onPressed: (loading || _uploadingPhoto) ? null : _save,
                //     child: loading || _uploadingPhoto
                //         ? const CircularProgressIndicator(color: Colors.white)
                //         : const Text(
                //             'Save Changes',
                //             style: TextStyle(fontSize: 16),
                //           ),
                //   ),
                // ),

                // const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;

  const _InitialsAvatar({required this.firstName, required this.lastName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();

    return Container(
      color: theme.colorScheme.primary.withOpacity(0.15),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
