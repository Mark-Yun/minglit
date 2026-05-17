// mds-emulator-render driver
//
// `integration_test/mds-emulator-render/<screen>/<screen>_test.dart` 의
// `binding.takeScreenshot('<screen>__<state>')` 호출을 받아
// `docs/infra/mds-emulator-render/<screen>/<state>.png` 에 저장.
//
// 이름 컨벤션 `<screen>__<state>` 사용 이유: Android 가 takeScreenshot 의
// args 파라미터 미지원 (`_callback_io.dart`: 'args == null' assertion).
//
// MDS 의 `apps/mds/docs/public/specs/<screen>/state_*.png` 와 1:1 비교 대상.
//
// 출력 경로 가정:
//   - flutter drive 의 cwd 는 `apps/app_user/` (`flutter drive` 실행 위치).
//   - `../../` 로 minglit 루트, 거기서 `docs/infra/mds-emulator-render/` 로 저장.
//   - 다른 cwd 에서 호출 시 misroute 가능 — `pwd` 확인 필수.
//
// 실행:
//   cd apps/app_user                               # ← 필수
//   flutter drive \
//     --driver=test_driver/mds_emulator_render_driver.dart \
//     --target=integration_test/mds-emulator-render/<screen>/<screen>_test.dart \
//     -d <device>

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

const _outputRoot = '../../docs/infra/mds-emulator-render';

/// 같은 (screen, state) 쌍이 한 run 안에서 중복 캡처되면 경고.
/// (테스트 코드 author 실수 감지 — 같은 이름 두 번 testWidgets 등.)
final Set<String> _seenNames = <String>{};

void _logErr(String msg) {
  stderr.writeln('[mds-emulator-render] $msg');
}

Future<void> main() => integrationDriver(
      onScreenshot: (
        String name,
        List<int> bytes, [
        Map<String, Object?>? args,
      ]) async {
        try {
          // name 컨벤션: <screen>__<state> (double underscore separator)
          final parts = name.split('__');
          if (parts.length != 2 || parts.any((p) => p.isEmpty)) {
            _logErr(
              'invalid name "$name" — expected "<screen>__<state>" format. skipped.',
            );
            return false;
          }
          final screen = parts[0];
          final stateName = parts[1];
          final outputPath = '$_outputRoot/$screen/$stateName.png';

          if (!_seenNames.add(name)) {
            _logErr('duplicate capture name "$name" — overwriting $outputPath');
          }

          final file = File(outputPath);
          await file.create(recursive: true);
          await file.writeAsBytes(bytes);

          stderr.writeln(
            '[mds-emulator-render] saved → $outputPath (${bytes.length} bytes)',
          );
          return true;
        } catch (e, st) {
          _logErr('failed to save "$name": $e\n$st');
          return false;
        }
      },
    );
