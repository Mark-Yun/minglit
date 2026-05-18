import 'package:app_partner/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultFirebaseOptions.currentPlatform', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('Android throws UnsupportedError (native auto-init guard)', () {
      // Regression for splash hang: Android must use native auto-init via
      // google-services Gradle plugin, not Dart-side options. If this guard
      // is removed by accident the SDK falls back to placeholder appId and
      // Firebase.initializeApp hangs.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        () => DefaultFirebaseOptions.currentPlatform,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('iOS returns options (placeholder until plist migration)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        DefaultFirebaseOptions.currentPlatform.iosBundleId,
        'com.minglit.appPartner',
      );
    });
  });
}
