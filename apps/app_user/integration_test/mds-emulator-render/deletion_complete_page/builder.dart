// DeletionCompletePageBuilder — deletion_complete_page 전용 fluent API.
//
// DeletionCompletePage 는 build() 에서 provider 를 watch 하지 않는다.
// 버튼 tap 시 authControllerProvider / appCoordinatorProvider 를 read 하지만
// 렌더 catalog 에서는 상호작용 없이 초기 UI 만 캡처하므로 별도 override 불필요.

import 'package:app_user/src/features/account_deletion/ui/deletion_complete_page.dart';

import '../_engine/builder.dart';

class DeletionCompletePageBuilder
    extends MdsScreenBuilder<DeletionCompletePage> {
  DeletionCompletePageBuilder() : super(page: const DeletionCompletePage());

  /// 다크 모드 토글.
  DeletionCompletePageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
