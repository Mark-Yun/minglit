// DeletionReasonPageBuilder — deletion_reason_page 전용 fluent API.
//
// DeletionReasonPage 는 ConsumerStatefulWidget 이며 내부 state 로
// 라디오 선택 및 텍스트 입력을 관리한다.
// 렌더 catalog 는 초기(미선택) 상태만 캡처한다.

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/account_deletion/ui/deletion_reason_page.dart';
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

class DeletionReasonPageBuilder extends MdsScreenBuilder<DeletionReasonPage> {
  DeletionReasonPageBuilder()
    : super(
        page: const DeletionReasonPage(),
        base: [
          accountDeletionCoordinatorProvider.overrideWithValue(
            _FakeDeletionCoordinator(),
          ),
        ],
      );

  /// 다크 모드 토글.
  DeletionReasonPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
