import 'package:carrygo/providers/phone_otp_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final otpCtrl = TextEditingController();
  bool otpSent = false;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    // final phone = doc['phone'];
    String phone = doc['phone'].toString().trim();

    // ✅ Ensure E.164 format (India)
    if (!phone.startsWith('+')) {
      phone = '+91$phone';
    }

    debugPrint('Sending OTP to: $phone');
    await ref.read(phoneOtpProvider.notifier).sendOtp(phone);
    setState(() => otpSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phoneOtpProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Enter the OTP sent to your phone',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit OTP'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.loading
                    ? null
                    : () => ref
                          .read(phoneOtpProvider.notifier)
                          .verifyOtp(otpCtrl.text),
                child: state.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify'),
              ),
            ),

            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
