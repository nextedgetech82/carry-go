import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

class PhoneOtpState {
  final bool loading;
  final String? verificationId;
  final String? error;

  const PhoneOtpState({this.loading = false, this.verificationId, this.error});

  PhoneOtpState copyWith({
    bool? loading,
    String? verificationId,
    String? error,
  }) {
    return PhoneOtpState(
      loading: loading ?? this.loading,
      verificationId: verificationId ?? this.verificationId,
      error: error,
    );
  }
}

final phoneOtpProvider =
    StateNotifierProvider<PhoneOtpController, PhoneOtpState>(
      (ref) => PhoneOtpController(),
    );

class PhoneOtpController extends StateNotifier<PhoneOtpState> {
  PhoneOtpController() : super(const PhoneOtpState());

  /// 📤 SEND OTP
  Future<void> sendOtp(String phone) async {
    state = state.copyWith(loading: true, error: null);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _linkCredential(credential);
      },

      verificationFailed: (e) {
        state = state.copyWith(loading: false, error: e.message);
      },

      codeSent: (verificationId, _) {
        state = state.copyWith(loading: false, verificationId: verificationId);
      },

      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// 🔐 VERIFY OTP
  Future<void> verifyOtp(String otp) async {
    try {
      state = state.copyWith(loading: true);

      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );

      await _linkCredential(credential);
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Invalid OTP');
    }
  }

  /// 🔗 LINK PHONE TO EMAIL USER
  Future<void> _linkCredential(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.linkWithCredential(credential);

    // 🔥 Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'phoneVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    state = state.copyWith(loading: false);
  }
}
