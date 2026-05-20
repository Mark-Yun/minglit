// PrivacyPageBuilder — privacy_page 전용 fluent API.
//
// PrivacyPage 는 consentControllerProvider 를 watch 한다.
// LoadedConsentController override 로 동의 목록을 주입.

import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/notifiers.dart';

class PrivacyPageBuilder extends MdsScreenBuilder<PrivacyPage> {
  PrivacyPageBuilder() : super(page: const PrivacyPage());

  /// 동의 목록 로드 완료 (필수 동의 + 선택 일부).
  PrivacyPageBuilder loaded() {
    addOverride(
      consentControllerProvider.overrideWith(LoadedConsentController.new),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 다크 모드 토글.
  PrivacyPageBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder
    return this;
  }
}
