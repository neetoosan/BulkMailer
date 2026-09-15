// Template file: Copy this file to lib/firebase_options.dart and add your Firebase credentials
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY',
    authDomain: 'flix-mailer.firebaseapp.com',
    projectId: 'flix-mailer',
    storageBucket: 'flix-mailer.firebasestorage.app',
    messagingSenderId: '1080585742808',
    appId: '1:1080585742808:web:27d8c404f8998a3866eaad',
    measurementId: 'G-8Z2RF66726',
  );
}