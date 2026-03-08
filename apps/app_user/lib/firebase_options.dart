// Firebase configuration per environment.
// Web configs added from Firebase Console.
// Android/iOS configs from google-services.json / GoogleService-Info.plist.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'local',
  );

  static bool get _isProduction => _environment == 'production';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _isProduction ? _webMain : _webDev;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _isProduction ? _androidMain : _androidDev;
      case TargetPlatform.iOS:
        return _isProduction ? _iosMain : _iosDev;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Web ────────────────────────────────────────────────────────────────

  static const FirebaseOptions _webDev = FirebaseOptions(
    apiKey: 'AIzaSyCjcktsWHHkJsi1EcTEBbrKRBODNVEPibQ',
    authDomain: 'minglit-dev-18e08.firebaseapp.com',
    appId: '1:282428044723:web:6818e556f6ff68ace007c6',
    messagingSenderId: '282428044723',
    projectId: 'minglit-dev-18e08',
    storageBucket: 'minglit-dev-18e08.firebasestorage.app',
    measurementId: 'G-W8F9DQLLTG',
  );

  static const FirebaseOptions _webMain = FirebaseOptions(
    apiKey: 'AIzaSyBo71oEpRo1WMRo2RHhm9POCte6ytvFFvI',
    authDomain: 'minglit-main-13375.firebaseapp.com',
    appId: '1:687100681844:web:e611c42b339e9e8986fb21',
    messagingSenderId: '687100681844',
    projectId: 'minglit-main-13375',
    storageBucket: 'minglit-main-13375.firebasestorage.app',
    measurementId: 'G-4D51HCTY0N',
  );

  // ── Android ────────────────────────────────────────────────────────────

  static const FirebaseOptions _androidDev = FirebaseOptions(
    apiKey: 'AIzaSyCjcktsWHHkJsi1EcTEBbrKRBODNVEPibQ',
    appId: '1:282428044723:android:0000000000000000',
    messagingSenderId: '282428044723',
    projectId: 'minglit-dev-18e08',
    storageBucket: 'minglit-dev-18e08.firebasestorage.app',
  );

  static const FirebaseOptions _androidMain = FirebaseOptions(
    apiKey: 'AIzaSyCRLBXsd3ksbPo2QpMaSRnJYbD1gZOovpk',
    appId: '1:687100681844:android:b9b92b523955912486fb21',
    messagingSenderId: '687100681844',
    projectId: 'minglit-main-13375',
    storageBucket: 'minglit-main-13375.firebasestorage.app',
  );

  // ── iOS ────────────────────────────────────────────────────────────────

  // TODO(firebase): Add iOS apps to Firebase console and update appId values.
  static const FirebaseOptions _iosDev = FirebaseOptions(
    apiKey: 'AIzaSyCjcktsWHHkJsi1EcTEBbrKRBODNVEPibQ',
    appId: '1:282428044723:ios:0000000000000000',
    messagingSenderId: '282428044723',
    projectId: 'minglit-dev-18e08',
    storageBucket: 'minglit-dev-18e08.firebasestorage.app',
    iosBundleId: 'com.minglit.appUser',
  );

  static const FirebaseOptions _iosMain = FirebaseOptions(
    apiKey: 'AIzaSyCRLBXsd3ksbPo2QpMaSRnJYbD1gZOovpk',
    appId: '1:687100681844:ios:0000000000000000',
    messagingSenderId: '687100681844',
    projectId: 'minglit-main-13375',
    storageBucket: 'minglit-main-13375.firebasestorage.app',
    iosBundleId: 'com.minglit.appUser',
  );
}
