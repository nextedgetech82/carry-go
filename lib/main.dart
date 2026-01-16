import 'package:carrygo/services/notification_service.dart';
import 'package:carrygo/services/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'router/app_router.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

final appRouter = AppRouter();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FirebaseFunctions.instance.useFunctionsEmulator(
  //   '10.0.2.2', // 🔥 NOT 127.0.0.1
  //   5001,
  // );

  //FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);

  //print(Firebase.app().options.projectId);

  await NotificationService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Travel Fetcher',
      home: const SplashScreen(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      onGenerateRoute: appRouter.onGenerateRoute,
      //Dhruv
      builder: (context, child) {
        PushNotificationService.init(context);
        return child!;
      },
    );
  }
}

// match /{document=**} {
//       allow read, write: if true;
//     }
