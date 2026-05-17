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
    MdsState('state-loaded', (b) => b, mdsIndex: 1),
    MdsState('state-dark', (b) => b.dark()),
  ],
);

void main() => MdsRenderEngine.run(catalog);
