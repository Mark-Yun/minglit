// MDS screen: privacy_page
// 대응 MDS: apps/mds/docs/public/specs/privacy_page/
//
// 출력: docs/infra/mds-emulator-render/privacy_page/state-*.png
//
// 주의: 로딩 상태(MinglitCircularProgressIndicator)는 애니메이션으로 인해
// pumpAndSettle 이 settle 되지 않아 제외. data/error/dark 만 포함.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PrivacyPageBuilder>(
  screen: 'privacy_page',
  mdsSpec: 'apps/mds/docs/public/specs/privacy_page/',
  builder: PrivacyPageBuilder.new,
  states: [
    MdsState('state-data', (b) => b, mdsIndex: 1),
    MdsState('state-error', (b) => b.error(), mdsIndex: 3),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
