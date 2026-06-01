// MDS screen: partner_member_permission_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/partner_member_permission_page/
//
// 출력: docs/infra/mds-emulator-render/partner_member_permission_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PartnerMemberPermissionPageBuilder>(
  screen: 'partner_member_permission_page',
  mdsSpec: 'apps/mds/docs/public/specs/partner_member_permission_page/',
  builder: PartnerMemberPermissionPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-owner-role', (b) => b.ownerRole(), mdsIndex: 2),
    MdsState('state-not-found', (b) => b.notFound(), mdsIndex: 3),
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 4,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b.error(), mdsIndex: 5),
  ],
);

void main() => MdsRenderEngine.run(catalog);
