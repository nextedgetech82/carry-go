import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'role_selection_state.dart';

final roleSelectionControllerProvider =
    StateNotifierProvider.autoDispose<
      RoleSelectionController,
      RoleSelectionState
    >((ref) => RoleSelectionController());

class RoleSelectionController extends StateNotifier<RoleSelectionState> {
  RoleSelectionController() : super(const RoleSelectionState());

  void selectRole(String role) {
    state = state.copyWith(selectedRole: role, error: null);
  }

  Future<void> submitSignup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (state.selectedRole == null) {
      state = state.copyWith(error: 'Please select a role');
      return;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': state.selectedRole,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Send verification
      if (!user.emailVerified) {
        await user.reload();
        await user.sendEmailVerification();
      }

      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}
