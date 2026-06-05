// MDS screen: notification_settings_screen
// 대응 MDS: apps/mds/docs/public/specs/notification_settings_screen/
//
// 출력: docs/infra/mds-emulator-render/notification_settings_screen/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<NotificationSettingsScreenBuilder>(
  screen: 'notification_settings_screen',
  mdsSpec: 'apps/mds/docs/public/specs/notification_settings_screen/',
  builder: NotificationSettingsScreenBuilder.new,
  states: [
    MdsState('state-mixed', (b) => b.mixed(), mdsIndex: 1),
    MdsState('state-all-off', (b) => b.allOff(), mdsIndex: 2),
    MdsState('state-all-on', (b) => b.allOn(), mdsIndex: 3),
    MdsState(
      'state-loading',
      (b) => b.loading(),
      mdsIndex: 4,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b.error(), mdsIndex: 5),
    // state_6 permission-denied is documented as a future implementation state.
    MdsState('state-dark', (b) => b.mixed().dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
