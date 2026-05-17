// mds-emulator-render driver
//
// `integration_test/mds-emulator-render/<screen>/<screen>_test.dart` 의
// `binding.takeScreenshot('<screen>__<state>')` 호출을 받아
// `docs/infra/mds-emulator-render/<screen>/<state>.png` 에 저장.
//
// 이름 컨벤션 `<screen>__<state>` 사용 이유: Android 에서 takeScreenshot 의
// args 파라미터 미지원 (`_callback_io.dart`: 'args == null' assertion).
//
// MDS 의 `apps/mds/docs/public/specs/<screen>/state_*.png` 와 1:1 비교 대상.
//
// 실행:
//   cd apps/app_user
//   flutter drive \
//     --driver=test_driver/mds_emulator_render_driver.dart \
//     --target=integration_test/mds-emulator-render/<screen>/<screen>_test.dart \
//     -d <device>

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

// Driver cwd 는 apps/app_user/ → ../../ 로 minglit 루트 접근.
const _outputRoot = '../../docs/infra/mds-emulator-render';

Future<void> main() => integrationDriver(
      onScreenshot: (
        String name,
        List<int> bytes, [
        Map<String, Object?>? args,
      ]) async {
        try {
          // name 컨벤션: <screen>__<state> (double underscore separator)
          final parts = name.split('__');
          if (parts.length != 2) {
            // ignore: avoid_print
            print(
              '[mds-emulator-render] invalid name "$name" '
              '— expected "<screen>__<state>" format',
            );
            return false;
          }
          final screen = parts[0];
          final stateName = parts[1];
          final outputPath = '$_outputRoot/$screen/$stateName.png';

          final file = File(outputPath);
          await file.create(recursive: true);
          await file.writeAsBytes(bytes);

          // ignore: avoid_print
          print(
            '[mds-emulator-render] saved → $outputPath (${bytes.length} bytes)',
          );
          return true;
        } catch (e, st) {
          // ignore: avoid_print
          print('[mds-emulator-render] failed to save "$name": $e\n$st');
          return false;
        }
      },
    );
