// MDS screen: bank_account_page (app_partner)
// 대응 MDS: apps/mds/docs/public/specs/bank_account_page/
//
// 출력: docs/infra/mds-emulator-render/bank_account_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<BankAccountPageBuilder>(
  screen: 'bank_account_page',
  mdsSpec: 'apps/mds/docs/public/specs/bank_account_page/',
  builder: BankAccountPageBuilder.new,
  states: [
    // Loading — partner 정보 로딩 중 스피너
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 1,
      infiniteAnimation: true,
    ),
    // No account — 등록된 계좌 없음
    MdsState('state-no-account', (b) => b.withNoAccount(), mdsIndex: 2),
    // With account — 계좌 정보 표시
    MdsState('state-with-account', (b) => b.withAccount(), mdsIndex: 3),
    // Dark variant
    MdsState('state-dark', (b) => b.withAccount().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
