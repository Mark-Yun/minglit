// MDS screen: verification_manage_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/verification_manage_page/
//
// 출력: docs/infra/mds-emulator-render/verification_manage_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<VerificationManagePageBuilder>(
  screen: 'verification_manage_page',
  mdsSpec: 'apps/mds/docs/public/specs/verification_manage_page/',
  builder: VerificationManagePageBuilder.new,
  states: [
    // Loading — MinglitAsyncValueWidget 로딩 스피너
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 1,
      infiniteAnimation: true,
    ),
    // Active empty — "생성된 인증이 없습니다" empty state
    MdsState('state-active-empty', (b) => b.withActiveEmpty(), mdsIndex: 2),
    // Active with items — 인증 목록 2개
    MdsState(
      'state-active-with-items',
      (b) => b.withActiveItems(),
      mdsIndex: 3,
    ),
    // Archived with items — 보관됨 탭
    MdsState(
      'state-archived-with-items',
      (b) => b.withArchivedItems(),
      mdsIndex: 4,
    ),
    // Dark variant
    MdsState('state-dark', (b) => b.withActiveItems().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
