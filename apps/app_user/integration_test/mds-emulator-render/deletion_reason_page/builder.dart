// DeletionReasonPageBuilder — deletion_reason_page 전용 fluent API.
//
// 기본 상태: 탈퇴 사유 미선택 (라디오 모두 unselected, 다음 버튼 비활성).
// accountDeletionCoordinatorProvider 는 build() 에서 ref.read() 로 접근하므로 mock 필수.

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

class DeletionReasonPageBuilder extends MdsScreenBuilder<DeletionReasonPage> {
  DeletionReasonPageBuilder()
    : super(
        page: const DeletionReasonPage(),
        base: [
          accountDeletionCoordinatorProvider.overrideWithValue(
            MockAccountDeletionCoordinator(),
          ),
        ],
      );

  /// 다크 모드 토글.
  DeletionReasonPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
