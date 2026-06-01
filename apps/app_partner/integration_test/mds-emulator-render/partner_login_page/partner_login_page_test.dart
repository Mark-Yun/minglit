// MDS screen: partner_login_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_login_page/
//
// 출력: docs/infra/mds-emulator-render/partner_login_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerLoginPageBuilder>(
  screen: 'partner_login_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_login_page/',
  builder: PartnerLoginPageBuilder.new,
  states: [
    // Default iOS/macOS/Web variant — Apple 버튼 포함 baseline.
    MdsState('state-default-ios', (b) => b.iosDefault(), mdsIndex: 1),
    // Default Android variant — Apple 버튼 미노출.
    MdsState('state-default-android', (b) => b.androidDefault(), mdsIndex: 2),
    // Loading — OAuth 처리 중 스피너 노출.
    MdsState('state-loading', (b) => b.loading(), mdsIndex: 3),
    // Auth Error — 인증 실패 후 에러 처리 상태.
    MdsState('state-auth-error', (b) => b.error(), mdsIndex: 4),
  ],
);

void main() => MdsRenderEngine.run(catalog);
