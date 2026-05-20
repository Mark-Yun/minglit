// MDS screen: create_verification_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/create_verification_page/
//
// 출력: docs/infra/mds-emulator-render/create_verification_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<CreateVerificationPageBuilder>(
  screen: 'create_verification_page',
  mdsSpec: 'apps/mds/docs/public/specs/create_verification_page/',
  builder: CreateVerificationPageBuilder.new,
  states: [
    // Empty — 필드 없는 빈 폼
    MdsState('state-empty', (b) => b.empty(), mdsIndex: 1),
    // With fields — 텍스트 + 파일 필드 2개 추가된 상태
    MdsState('state-with-fields', (b) => b.withFields(), mdsIndex: 2),
    // Dark variant
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
