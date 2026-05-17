// MDS screen: notification_list_screen
// 대응 MDS: apps/mds/docs/public/specs/notification_list_screen/
//
// 출력: docs/infra/mds-emulator-render/notification_list_screen/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<NotificationListScreenBuilder>(
  screen: 'notification_list_screen',
  mdsSpec: 'apps/mds/docs/public/specs/notification_list_screen/',
  builder: NotificationListScreenBuilder.new,
  states: [
    MdsState('state-empty', (b) => b.withEmpty(), mdsIndex: 1),
    MdsState(
      'state-with-notifications',
      (b) => b.withNotifications(),
      mdsIndex: 2,
    ),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
