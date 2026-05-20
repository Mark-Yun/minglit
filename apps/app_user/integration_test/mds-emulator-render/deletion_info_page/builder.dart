// DeletionInfoPageBuilder — deletion_info_page 전용 fluent API.
//
// DeletionInfoPage 는 reasonCode/reasonText 를 생성자 파라미터로 받으므로
// 사유 유무에 따른 state 는 별도 named constructor 로 분기한다.
// (Riverpod provider override 로 주입 불가 — page 생성자 파라미터)

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_info_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../_engine/builder.dart';

class _FakeDeletionCoordinator extends AccountDeletionCoordinator {
  _FakeDeletionCoordinator()
    : super(
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      );
}

/// deletion_info_page 의 기본 상태 builder (탈퇴 사유 없이 진입).
class DeletionInfoPageBuilder extends MdsScreenBuilder<DeletionInfoPage> {
  DeletionInfoPageBuilder()
    : super(
        page: const DeletionInfoPage(),
        base: [
          accountDeletionCoordinatorProvider.overrideWithValue(
            _FakeDeletionCoordinator(),
          ),
        ],
      );

  /// 다크 모드 토글.
  DeletionInfoPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}

/// deletion_info_page 의 사유 포함 상태 builder (privacy_concern 사유 선택 후 진입).
class DeletionInfoWithReasonBuilder extends MdsScreenBuilder<DeletionInfoPage> {
  DeletionInfoWithReasonBuilder()
    : super(
        page: const DeletionInfoPage(reasonCode: 'privacy_concern'),
        base: [
          accountDeletionCoordinatorProvider.overrideWithValue(
            _FakeDeletionCoordinator(),
          ),
        ],
      );

  /// 다크 모드 토글.
  DeletionInfoWithReasonBuilder dark() {
    useDarkTheme();
    return this;
  }
}
