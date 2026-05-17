// PrivacyPageBuilder — privacy_page 전용 fluent API.
//
// 기본 상태: 동의 없는 유저 (user=null) → ConsentController 가 빈 list 반환.
// 동의 SwitchTile 전부 off, 읽기 전용 tile 은 동의됨 표시.

import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/notifiers.dart';

class PrivacyPageBuilder extends MdsScreenBuilder<PrivacyPage> {
  PrivacyPageBuilder() : super(page: const PrivacyPage(), base: []);

  /// 동의 정보 로드 실패 상태.
  PrivacyPageBuilder error() {
    addOverride(
      consentControllerProvider.overrideWith(ErrorConsentController.new),
    );
    return this;
  }

  /// 다크 모드 토글.
  PrivacyPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
