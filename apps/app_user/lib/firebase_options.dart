// File generated manually from google-services.json.
// To regenerate, run `flutterfire configure` in this directory.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCRLBXsd3ksbPo2QpMaSRnJYbD1gZOovpk',
    appId: '1:687100681844:android:b9b92b523955912486fb21',
    messagingSenderId: '687100681844',
    projectId: 'minglit-main-13375',
    storageBucket: 'minglit-main-13375.firebasestorage.app',
  );

  // TODO(firebase): Add iOS app to Firebase console and update these values.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCRLBXsd3ksbPo2QpMaSRnJYbD1gZOovpk',
    appId: '1:687100681844:ios:0000000000000000',
    messagingSenderId: '687100681844',
    projectId: 'minglit-main-13375',
    storageBucket: 'minglit-main-13375.firebasestorage.app',
    iosBundleId: 'com.minglit.appUser',
  );
}
