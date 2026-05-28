// MDS screen: purchase_history_detail_page
// 대응 MDS: apps/mds/docs/public/specs/purchase_history_detail_page/
//
// 출력: docs/infra/mds-emulator-render/purchase_history_detail_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<PurchaseHistoryDetailPageBuilder>(
  screen: 'purchase_history_detail_page',
  mdsSpec: 'apps/mds/docs/public/specs/purchase_history_detail_page/',
  builder: PurchaseHistoryDetailPageBuilder.new,
  states: [
    MdsState(
      'state-default',
      (b) {
        b.withDefault();
        return b;
      },
      mdsIndex: 1,
    ),
    MdsState(
      'state-cancel-disabled',
      (b) {
        b.withCancelDisabled();
        return b;
      },
      mdsIndex: 2,
    ),
    MdsState(
      'state-refunded',
      (b) {
        b.withRefunded();
        return b;
      },
      mdsIndex: 3,
    ),
    MdsState(
      'state-payment-failed',
      (b) {
        b.withPaymentFailed();
        return b;
      },
      mdsIndex: 4,
    ),
    MdsState(
      'state-loading',
      (b) {
        b.withLoading();
        return b;
      },
      mdsIndex: 5,
      infiniteAnimation: true,
    ),
    MdsState(
      'state-error',
      (b) {
        b.withError();
        return b;
      },
      mdsIndex: 6,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
