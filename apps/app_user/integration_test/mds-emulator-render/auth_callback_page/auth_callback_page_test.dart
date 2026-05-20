// MDS screen: auth_callback_page
// 대응 MDS: apps/mds/docs/public/specs/auth_callback_page/
//
// 출력: docs/infra/mds-emulator-render/auth_callback_page/state-*.png
//
// state_1 = 로딩 중 (스피너 + "로그인 처리 중입니다...")
//   infiniteAnimation: true 로 10초 타이머 발동 방지.
// state_2, state_3 = 타이머 발동 후 타임아웃 에러 / 다크 — 별도 PR 예정
//   (타이머 발동은 pumpAndSettle fake-time 진행 10초 필요 → 별도 처리 필요).

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<AuthCallbackPageBuilder>(
  screen: 'auth_callback_page',
  mdsSpec: 'apps/mds/docs/public/specs/auth_callback_page/',
  builder: AuthCallbackPageBuilder.new,
  states: [
    MdsState(
      'state-loading',
      (b) => b,
      mdsIndex: 1,
      // 10초 타이머 발동 전에 캡처하도록 infiniteAnimation 플래그 사용.
      infiniteAnimation: true,
    ),
    MdsState(
      'state-loading-dark',
      (b) => b.dark(),
      infiniteAnimation: true,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
