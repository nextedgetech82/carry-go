import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'signin_state.dart';

final signinProvider = StateNotifierProvider<SigninController, SigninState>(
  (ref) => SigninController(),
);

class SigninController extends StateNotifier<SigninState> {
  SigninController() : super(const SigninState());

  void togglePassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
    required WidgetRef ref, // 🔥 IMPORTANT
  }) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    state = state.copyWith(loading: true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      await user.reload();

      if (!user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email before signing in'),
          ),
        );
      }

      // 🔥🔥 CRITICAL LINE
      ref.invalidate(startupProvider);

      // 🔁 Go back to splash (fresh evaluation)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email';
          break;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}
