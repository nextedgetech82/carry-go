import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase options for each supported platform.
///
/// These values were extracted from the existing Android google-services.json
/// so iOS/macOS can initialize without relying on a missing
/// GoogleService-Info.plist. Replace the apple config with the exact values
/// from your Firebase console when available.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return apple;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyhQBN5tTxQm9GSuqRwlSsxnW5k-5POx4',
    appId: '1:1054532127126:android:0121ba4da5d0c35fe4f5b7',
    messagingSenderId: '1054532127126',
    projectId: 'carrygo-55444',
    storageBucket: 'carrygo-55444.firebasestorage.app',
  );

  static const FirebaseOptions apple = FirebaseOptions(
    apiKey: 'AIzaSyCyhQBN5tTxQm9GSuqRwlSsxnW5k-5POx4',
    appId: '1:1054532127126:ios:0121ba4da5d0c35fe4f5b7',
    messagingSenderId: '1054532127126',
    projectId: 'carrygo-55444',
    storageBucket: 'carrygo-55444.firebasestorage.app',
    iosBundleId: 'com.carrygo.app',
  );
}
