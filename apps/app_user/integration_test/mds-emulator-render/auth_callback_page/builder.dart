// AuthCallbackPageBuilder — auth_callback_page 전용 fluent API.
//
// AuthCallbackPage 는 ConsumerStatefulWidget — initState 에서 10초 타이머를
// 설정한다. 렌더 catalog 에서는 타이머가 발동하기 전 초기 로딩 UI 만 캡처.
// pumpAndSettle 이 fake-time 을 10초 진행하기 전에 infiniteAnimation 플래그로
// 고정 pump 를 사용해 타이머 발동을 방지한다.
//
// currentUserProvider 가 null 이면 (공통 override) redirect 없이 로딩 상태 유지.

import 'package:app_user/src/features/auth/ui/auth_callback_page.dart';
import 'package:app_user/src/logic/auth_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

class AuthCallbackPageBuilder extends MdsScreenBuilder<AuthCallbackPage> {
  AuthCallbackPageBuilder()
    : super(
        page: const AuthCallbackPage(),
        base: [
          // authCoordinatorProvider 를 mock 으로 교체 — 리디렉션 방지.
          authCoordinatorProvider.overrideWithValue(
            _createNoOpAuthCoordinator(),
          ),
        ],
      );

  /// 다크 모드 토글.
  AuthCallbackPageBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder
    return this;
  }
}

/// 모든 메서드가 no-op 인 AuthCoordinator mock.
MockAuthCoordinator _createNoOpAuthCoordinator() {
  final mock = MockAuthCoordinator();
  when(mock.goToLogin).thenReturn(null);
  when(() => mock.goToReturnLocation(any())).thenReturn(null);
  return mock;
}
