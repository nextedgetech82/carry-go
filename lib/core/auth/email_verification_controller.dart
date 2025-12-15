import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'email_verification_state.dart';

final emailVerificationControllerProvider =
    StateNotifierProvider<EmailVerificationController, EmailVerificationState>(
      (ref) => EmailVerificationController(),
    );

class EmailVerificationController
    extends StateNotifier<EmailVerificationState> {
  EmailVerificationController() : super(const EmailVerificationState()) {
    _startPolling();
  }

  Timer? _timer;

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user != null && user.emailVerified) {
        state = state.copyWith(verified: true);
        _timer?.cancel();
      }
    });
  }

  Future<void> resendEmail() async {
    state = state.copyWith(sending: true);

    await FirebaseAuth.instance.currentUser?.sendEmailVerification();

    state = state.copyWith(sending: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
