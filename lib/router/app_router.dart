import 'package:carrygo/core/startup/legal_acceptance_screen.dart';
import 'package:flutter/material.dart';

import '../ui/screens/onboarding/onboarding_screen.dart';
import '../ui/screens/signup/signup_screen.dart';
import '../ui/screens/splash/splash_screen.dart';

/// Simple manual router that maps route names to screens.
class AppRouter {
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case '/legal': // 🔐 NEW
        return _page(const LegalAcceptanceScreen());
      case '/':
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }

  /// Common page wrapper (future-proof for transitions)
  MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
