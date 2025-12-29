import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/startup/startup_provider.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;

  const PhoneOtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool loading = false;
  bool canResend = false;

  static const int _resendSeconds = 60;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _resendSeconds;
      canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() => canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;

    setState(() {
      loading = true;
      canResend = false;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (_) {},
        verificationFailed: (e) => throw e,
        codeSent: (newVerificationId, _) {
          _verificationId = newVerificationId; // ✅ FIX
          _startTimer();
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => canResend = true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => loading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpCtrl.text.trim(),
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final uid = userCred.user!.uid;
      final users = FirebaseFirestore.instance.collection('users');
      final doc = await users.doc(uid).get();

      if (!doc.exists) {
        await users.doc(uid).set({
          'phone': widget.phone,
          'phoneVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await users.doc(uid).update({'phoneVerified': true});
      }

      /// 🔁 FORCE SPLASH TO RE-RUN STARTUP LOGIC
      ref.invalidate(startupProvider);

      /// 🔁 NAVIGATE BACK TO SPLASH
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Verify OTP',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _verifyOtp,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Verify & Continue'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: canResend && !loading ? _resendOtp : null,
                child: Text(
                  canResend
                      ? 'Resend OTP'
                      : 'Resend OTP in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
