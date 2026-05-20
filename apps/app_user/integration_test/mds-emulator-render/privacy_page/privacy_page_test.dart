// MDS screen: privacy_page
// 대응 MDS: apps/mds/docs/public/specs/privacy_page/
//
// 출력: docs/infra/mds-emulator-render/privacy_page/state-*.png
//
// state_1 = 로딩 (consentControllerProvider AsyncLoading)
// state_2 = 동의 목록 표시 (loaded)
// state_3 = 다크 모드

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PrivacyPageBuilder>(
  screen: 'privacy_page',
  mdsSpec: 'apps/mds/docs/public/specs/privacy_page/',
  builder: PrivacyPageBuilder.new,
  states: [
    // 기본 state 는 consentControllerProvider AsyncLoading (override 없음).
    MdsState('state-loading', (b) => b, mdsIndex: 1),
    MdsState('state-loaded', (b) => b.loaded(), mdsIndex: 2),
    MdsState('state-dark', (b) => b.loaded().dark(), mdsIndex: 3),
  ],
);

void main() => MdsRenderEngine.run(catalog);
