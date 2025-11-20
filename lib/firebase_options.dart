import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseOptions, FirebaseApp;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZQY29vdxJYN_8yb0GaqX2gzZK0HQE34o',
    appId: '1:216938110229:web:8b87b542b1ebe6adeb5d1c',
    messagingSenderId: '216938110229',
    projectId: 'ibrgy-mobile-app-services',
    authDomain: 'ibrgy-mobile-app-services.firebaseapp.com',
    databaseURL:
        'https://ibrgy-mobile-app-services-default-rtdb.firebaseio.com',
    storageBucket: 'ibrgy-mobile-app-services.firebasestorage.app',
    measurementId: 'G-TREW32DJHY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGju8dwB5iav1SmkiQCpwrVRopWezeKXc',
    appId: '1:216938110229:android:afd7662a9b747e59eb5d1c',
    messagingSenderId: '216938110229',
    projectId: 'ibrgy-mobile-app-services',
    databaseURL:
        'https://ibrgy-mobile-app-services-default-rtdb.firebaseio.com',
    storageBucket: 'ibrgy-mobile-app-services.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4UVJxE1v1pDIqo1wZ4FUPm5AOXsv1WXM',
    appId: '1:216938110229:ios:3f9d58c50abdf77feb5d1c',
    messagingSenderId: '216938110229',
    projectId: 'ibrgy-mobile-app-services',
    databaseURL:
        'https://ibrgy-mobile-app-services-default-rtdb.firebaseio.com',
    storageBucket: 'ibrgy-mobile-app-services.firebasestorage.app',
    iosBundleId: 'com.example.ibrgyMobileAppServices',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC4UVJxE1v1pDIqo1wZ4FUPm5AOXsv1WXM',
    appId: '1:216938110229:ios:3f9d58c50abdf77feb5d1c',
    messagingSenderId: '216938110229',
    projectId: 'ibrgy-mobile-app-services',
    databaseURL:
        'https://ibrgy-mobile-app-services-default-rtdb.firebaseio.com',
    storageBucket: 'ibrgy-mobile-app-services.firebasestorage.app',
    iosBundleId: 'com.example.ibrgyMobileAppServices',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCZQY29vdxJYN_8yb0GaqX2gzZK0HQE34o',
    appId: '1:216938110229:web:e2750c18fe46c0b0eb5d1c',
    messagingSenderId: '216938110229',
    projectId: 'ibrgy-mobile-app-services',
    authDomain: 'ibrgy-mobile-app-services.firebaseapp.com',
    databaseURL:
        'https://ibrgy-mobile-app-services-default-rtdb.firebaseio.com',
    storageBucket: 'ibrgy-mobile-app-services.firebasestorage.app',
    measurementId: 'G-NWM2YRXS8G',
  );
}

/// Convenience helper that initializes Firebase using the generated
/// [DefaultFirebaseOptions].
///
/// Example:
/// ```dart
/// await initializeFirebase();
/// ```
Future<FirebaseApp> initializeFirebase() async {
  return await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
