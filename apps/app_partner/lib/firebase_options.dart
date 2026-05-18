// Firebase configuration.
// Android: native auto-init via `com.google.gms.google-services` Gradle plugin
//   → `src/<flavor>/google-services.json` 가 build 시 처리.
//   → Dart 측에선 `Firebase.initializeApp()` 을 options 없이 호출.
// iOS: 아직 native plist 미구성 — Dart options 사용 중 (TODO: GoogleService-Info.plist).
// Web: 미지원 (현재 partner 는 web target 없음).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  /// iOS 용 options. Android 는 native auto-init 이므로 호출자가 이 분기를
  /// 피하고 `Firebase.initializeApp()` 을 options 없이 사용해야 한다.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'app_partner 는 web target 미지원.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Android Firebase 는 google-services Gradle plugin 으로 native auto-init. '
          '`Firebase.initializeApp()` 을 options 인자 없이 호출하라.',
        );
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── iOS ────────────────────────────────────────────────────────────────
  //
  // TODO(firebase-ios): iOS 도 Android 처럼 native plist (`GoogleService-Info.plist`)
  // 기반 auto-init 로 마이그. 현재 appId placeholder `0000000000000000` 는
  // 임시값 — iOS 빌드 시 Firebase init 가 hang 또는 fail 가능. iOS 작업 시
  // Firebase console 에서 iOS app 등록 → plist 다운로드 → Runner target 에 추가 →
  // 이 section 제거 + currentPlatform 의 iOS 분기도 `throw UnsupportedError` 로 변경.

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyCRLBXsd3ksbPo2QpMaSRnJYbD1gZOovpk',
    appId: '1:687100681844:ios:0000000000000000',
    messagingSenderId: '687100681844',
    projectId: 'minglit-main-13375',
    storageBucket: 'minglit-main-13375.firebasestorage.app',
    iosBundleId: 'com.minglit.appPartner',
  );
}
