import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/environment_info.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('collectEnvironmentInfo', () {
    test('returns a map with all 8 expected keys', () async {
      final info = await collectEnvironmentInfo();

      expect(info, isA<Map<String, dynamic>>());
      expect(
        info.keys,
        containsAll([
          'appVersion',
          'buildNumber',
          'platform',
          'osVersion',
          'deviceModel',
          'screenSize',
          'networkStatus',
          'batteryLevel',
        ]),
      );
      expect(info.length, equals(8));
    });

    test('returns a map with correct value types', () async {
      final info = await collectEnvironmentInfo();

      expect(info['appVersion'], anyOf(isNull, isA<String>()));
      expect(info['buildNumber'], anyOf(isNull, isA<String>()));
      expect(info['platform'], anyOf(isNull, isA<String>()));
      expect(info['osVersion'], anyOf(isNull, isA<String>()));
      expect(info['deviceModel'], anyOf(isNull, isA<String>()));
      expect(info['screenSize'], anyOf(isNull, isA<String>()));
      expect(info['networkStatus'], anyOf(isNull, isA<String>()));
      expect(info['batteryLevel'], anyOf(isNull, isA<int>()));
    });

    test('completes without throwing exceptions', () async {
      expect(
        collectEnvironmentInfo,
        returnsNormally,
      );
    });
  });
}
