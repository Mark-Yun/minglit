// DeletionCompletePageBuilder — deletion_complete_page 전용 fluent API.
//
// 기본 상태: 탈퇴 완료 화면 (icon + message + button).
// 버튼 콜백(authControllerProvider, appCoordinatorProvider)은 렌더 중
// 호출되지 않아 override 불필요.

import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';

import '../_engine/builder.dart';

class DeletionCompletePageBuilder
    extends MdsScreenBuilder<DeletionCompletePage> {
  DeletionCompletePageBuilder()
    : super(page: const DeletionCompletePage(), base: []);

  /// 다크 모드 토글.
  DeletionCompletePageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
