import 'package:carrygo/services/notification_service.dart';
import 'package:carrygo/services/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

final appRouter = AppRouter();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Notifications
  await NotificationService.init();

  // 🔐 Handle passwordless email link (cold start)
  //await _handleEmailLinkAtStartup();

  runApp(const ProviderScope(child: MyApp()));
}

/// ------------------------------------------------------------
/// 🔐 PASSWORDLESS EMAIL LINK HANDLER (COLD + WARM START)
/// ------------------------------------------------------------
// Future<void> _handleEmailLinkAtStartup() async {
//   final auth = FirebaseAuth.instance;

//   // 🔹 Cold start
//   final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

//   if (initialLink != null) {
//     await _processEmailLink(initialLink.link.toString());
//   }

//   // 🔹 App already running / resumed
//   FirebaseDynamicLinks.instance.onLink.listen((event) async {
//     await _processEmailLink(event.link.toString());
//   });
// }

// Future<void> _processEmailLink(String deepLink) async {
//   final auth = FirebaseAuth.instance;

//   if (!auth.isSignInWithEmailLink(deepLink)) return;

//   final prefs = await SharedPreferences.getInstance();
//   final email = prefs.getString('emailForSignIn');

//   if (email == null) return;

//   try {
//     final credential = EmailAuthProvider.credentialWithLink(
//       email: email,
//       emailLink: deepLink,
//     );

//     // 🔥 Link email to existing phone user
//     await auth.currentUser!.linkWithCredential(credential);

//     await prefs.remove('emailForSignIn');

//     // Refresh auth state
//     await auth.currentUser!.reload();

//     debugPrint('✅ Email linked & verified successfully');
//   } catch (e) {
//     debugPrint('❌ Email link failed: $e');
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CarryGo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
      onGenerateRoute: appRouter.onGenerateRoute,

      builder: (context, child) {
        // 🔔 Push notifications (context-safe)
        PushNotificationService.init(context);
        return child!;
      },
    );
  }
}
