import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.', // linux, macos, windows 제외
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD9n8Aku3T2OCNgoJm01mE8V8vqmUz7XQw',
    appId: '1:343081223442:web:ad1ae058cbcfecdebe9fcb',
    messagingSenderId: '343081223442',
    projectId: 'si-gonggoo-app-pjh',
    authDomain: 'si-gonggoo-app-pjh.firebaseapp.com',
    storageBucket: 'si-gonggoo-app-pjh.firebasestorage.app',
    measurementId: 'G-1CJSLND6P2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSZM0yNsAm85zBuZeWp-FNMIt_5iHDRXI',
    appId: '1:343081223442:android:76fc986aa044650abe9fcb',
    messagingSenderId: '343081223442',
    projectId: 'si-gonggoo-app-pjh',
    storageBucket: 'si-gonggoo-app-pjh.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtHz-LRGUAN43OcXeFEWAGBmv2jXBU5R0',
    appId: '1:343081223442:ios:f21399a5600dee9abe9fcb',
    messagingSenderId: '343081223442',
    projectId: 'si-gonggoo-app-pjh',
    storageBucket: 'si-gonggoo-app-pjh.firebasestorage.app',
    iosBundleId: 'com.watchman.gonggooApp',
  );
}
