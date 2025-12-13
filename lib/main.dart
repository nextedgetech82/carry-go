import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'router/app_router.dart';
import 'ui/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

final appRouter = AppRouter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CarryGo',
      home: const SplashScreen(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      onGenerateRoute: appRouter.onGenerateRoute,
    );
  }
}
