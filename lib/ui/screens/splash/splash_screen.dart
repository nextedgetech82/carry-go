import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/app_startup_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../signup/signup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await Future.delayed(const Duration(seconds: 2));

    final onboardingDone = await AppStartupService.isOnboardingDone();

    if (!mounted) return;

    _goTo(const OnboardingScreen());
    return;
    // if (!onboardingDone) {
    //   _goTo(const OnboardingScreen());
    //   return;
    // }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _goTo(const SignupScreen());
    } else {
      // TEMP (later we add role logic)
      _goTo(const SignupScreen());
    }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'CarryGo',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
