import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'signup_state.dart';

final signupProvider = StateNotifierProvider<SignupController, SignupState>(
  (ref) => SignupController(),
);

class SignupController extends StateNotifier<SignupState> {
  SignupController() : super(const SignupState());

  void togglePassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void setAgreed(bool value) {
    state = state.copyWith(agreed: value);
  }

  bool validateForm(GlobalKey<FormState> formKey, BuildContext context) {
    if (!formKey.currentState!.validate() || !state.agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return false;
    }
    return true;
  }
}
