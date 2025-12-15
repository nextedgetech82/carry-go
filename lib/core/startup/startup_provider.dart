import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/app_startup_service.dart';
import 'startup_result.dart';

final startupProvider = FutureProvider<StartupResult>((ref) async {
  // Splash delay (UX)
  await Future.delayed(const Duration(seconds: 2));

  // 1️⃣ Onboarding
  final onboardingDone = await AppStartupService.isOnboardingDone();
  if (!onboardingDone) {
    return StartupResult.onboarding;
  }

  // 2️⃣ Auth
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    //return StartupResult.signup;
    return StartupResult.signin;
  }

  await user.reload();

  // 3️⃣ Email verification
  if (!user.emailVerified) {
    return StartupResult.emailVerification;
  }

  // 4️⃣ Firestore user
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  // 5️⃣ Phone verification ✅ NEW
  //final data = doc.data()!;
  // final phoneVerified = data['phoneVerified'] == true;
  // if (!phoneVerified) {
  //   return StartupResult.phoneVerification;
  // }
  if (!doc.exists) {
    //return StartupResult.signup;
    return StartupResult.signin;
  }

  final role = doc.data()?['role'];

  if (role == 'traveller') {
    return StartupResult.travellerDashboard;
  } else if (role == 'sender') {
    return StartupResult.senderDashboard;
  } else {
    return StartupResult.roleSelection;
  }
});
