// DeletionInfoPageBuilder — deletion_info_page 전용 fluent API.
//
// 기본 상태: 탈퇴 사유 없음 (reasonCode=null) → 사유 카드 미노출.
// accountDeletionCoordinatorProvider 는 build() 에서 ref.read() 로 접근하므로 mock 필수.

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

class DeletionInfoPageBuilder extends MdsScreenBuilder<DeletionInfoPage> {
  DeletionInfoPageBuilder()
    : super(
        page: const DeletionInfoPage(),
        base: [
          accountDeletionCoordinatorProvider.overrideWithValue(
            MockAccountDeletionCoordinator(),
          ),
        ],
      );

  /// 다크 모드 토글.
  DeletionInfoPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
