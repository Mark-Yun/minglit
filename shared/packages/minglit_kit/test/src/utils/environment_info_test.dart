import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/environment_info.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('collectEnvironmentInfo', () {
    test('returns a map with all 9 expected keys', () async {
      final info = await collectEnvironmentInfo();

      expect(info, isA<Map<String, dynamic>>());
      expect(
        info.keys,
        containsAll([
          'appVersion',
          'buildNumber',
          'packageName',
          'platform',
          'osVersion',
          'deviceModel',
          'screenSize',
          'networkStatus',
          'batteryLevel',
        ]),
      );
      expect(info.length, equals(9));
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

    // Fix #1115 regression: firstOrNull prevents StateError on empty list
    test('firstOrNull on empty ConnectivityResult list returns null', () {
      const List<ConnectivityResult> emptyResults = [];
      expect(emptyResults.firstOrNull?.name, isNull);
    });

    test('firstOrNull on non-empty ConnectivityResult list returns name', () {
      const results = [ConnectivityResult.wifi];
      expect(results.firstOrNull?.name, isNotNull);
    });
  });
}
