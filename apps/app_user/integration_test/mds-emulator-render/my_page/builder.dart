// MyPageBuilder — my_page 전용 fluent API.
//
// 기본 상태: 비로그인 (currentUserProvider=null) → 로그인 안내 화면.
// 로그인 상태는 currentUserProvider 중복 override 제약(Riverpod 3.x)으로 제외.

import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/home/my_page.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

class MyPageBuilder extends MdsScreenBuilder<MyPage> {
  MyPageBuilder()
    : super(
        page: const MyPage(),
        base: [
          homeCoordinatorProvider.overrideWithValue(MockHomeCoordinator()),
        ],
      );

  /// 다크 모드 토글.
  MyPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
