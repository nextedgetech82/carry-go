import 'package:carrygo/ui/screens/signin/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/startup/startup_provider.dart';
import '../../../core/startup/startup_result.dart';

import '../onboarding/onboarding_screen.dart';
import '../signup/signup_screen.dart';
import '../signup/email_verification_screen.dart';
import '../signup/role_selection.dart';
import '../dashboard/traveller_dashboard.dart';
import '../dashboard/sender_dashboard.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(startupProvider, (previous, next) {
      next.whenData((result) {
        _navigate(context, result);
      });
    });

    return const Scaffold(
      body: Center(
        child: Text(
          'Travel Fetcher',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, StartupResult result) {
    Widget page;

    switch (result) {
      case StartupResult.onboarding:
        page = const OnboardingScreen();
        break;
      case StartupResult.signin:
        page = const SigninScreen();
        break;
      case StartupResult.signup:
        page = const SignupScreen();
        break;

      case StartupResult.emailVerification:
        page = const EmailVerificationScreen();
        break;

      case StartupResult.travellerDashboard:
        page = const TravellerDashboard();
        break;

      case StartupResult.senderDashboard:
        page = const SenderDashboard();
        break;

      case StartupResult.roleSelection:
        // role missing, redirect to signup or role selection flow
        page = const SignupScreen();
        break;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }
}
