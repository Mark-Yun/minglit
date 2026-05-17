#!/usr/bin/env dart
// MDS render coverage reconciler.
//
// 파일시스템만 스캔 (Flutter SDK / dart import 의존 없음):
//   - MDS spec: apps/mds/docs/public/specs/<screen>/state_*.png
//   - Cataloged: apps/app_user/integration_test/mds-emulator-render/<screen>/
//   - Captured: docs/infra/mds-emulator-render/<screen>/state-*.png
//
// 사용:
//   dart run scripts/mds_render_coverage.dart            # 사람 친화 출력
//   dart run scripts/mds_render_coverage.dart --json     # JSON
//
// 종료 코드:
//   0 — 100% 화면 커버리지 + orphan 0
//   1 — 부족 (uncovered screens 또는 orphan catalogs 존재)
//   2 — 스크립트 자체 에러
//
// 주의: catalog 메타 (mdsIndex 등) 는 본 스크립트에서 접근 안 함. manifest
// 작성은 Phase 2b 에서 별도 메커니즘으로 처리.

import 'dart:convert';
import 'dart:io';

const _mdsSpecsRoot = 'apps/mds/docs/public/specs';
const _catalogRoot =
    'apps/app_user/integration_test/mds-emulator-render';
const _renderRoot = 'docs/infra/mds-emulator-render';

void main(List<String> args) {
  try {
    final json = args.contains('--json');

    // MDS screen = `state_*.png` 가 1개 이상 있는 dir 만.
    // (components 같은 컴포넌트 폴더 / `_template`, `_authoring` 제외)
    final mdsScreens = _listDirs(_mdsSpecsRoot)
        .where((d) => !d.startsWith('_'))
        .where((d) => _countPngs('$_mdsSpecsRoot/$d', 'state_') > 0)
        .toList();
    final cataloged = _listDirs(_catalogRoot)
        .where((d) => !d.startsWith('_')) // _engine, _mocks 등 제외
        .toList();

    final uncovered = mdsScreens.where((s) => !cataloged.contains(s)).toList();
    final orphan = cataloged.where((c) => !mdsScreens.contains(c)).toList();

    final perScreen = <Map<String, dynamic>>[];
    for (final screen in cataloged) {
      final mdsStateCount = _countPngs('$_mdsSpecsRoot/$screen', 'state_');
      final capturedCount = _countPngs('$_renderRoot/$screen', 'state-');
      perScreen.add({
        'screen': screen,
        'mds_state_pngs': mdsStateCount,
        'captured_pngs': capturedCount,
        'complete': capturedCount >= mdsStateCount && mdsStateCount > 0,
      });
    }

    final screenPct = mdsScreens.isEmpty
        ? 100.0
        : (cataloged.toSet().intersection(mdsScreens.toSet()).length /
                mdsScreens.length) *
            100;

    final summary = {
      'mds_screens': mdsScreens.length,
      'cataloged_screens': cataloged.length,
      'screen_coverage_pct': screenPct.toStringAsFixed(1),
      'uncovered_screens': uncovered..sort(),
      'orphan_catalogs': orphan..sort(),
      'per_screen': perScreen,
    };

    if (json) {
      print(const JsonEncoder.withIndent('  ').convert(summary));
    } else {
      _printHuman(summary);
    }

    exit(uncovered.isEmpty && orphan.isEmpty ? 0 : 1);
  } catch (e, st) {
    stderr.writeln('[coverage] error: $e\n$st');
    exit(2);
  }
}

/// [path] 안의 모든 디렉토리 이름 (basename).
List<String> _listDirs(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return [];
  return dir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList()
    ..sort();
}

/// [dirPath] 안의 `<prefix>*.png` 파일 개수.
int _countPngs(String dirPath, String prefix) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return 0;
  return dir
      .listSync()
      .whereType<File>()
      .where((f) {
        final name = f.uri.pathSegments.last;
        return name.startsWith(prefix) && name.endsWith('.png');
      })
      .length;
}

void _printHuman(Map<String, dynamic> s) {
  print('═' * 60);
  print('  MDS Render Coverage');
  print('═' * 60);
  print('  Total MDS screens     : ${s['mds_screens']}');
  print('  Cataloged screens     : ${s['cataloged_screens']}');
  print('  Screen coverage       : ${s['screen_coverage_pct']}%');
  print('');
  print('─── Per-screen ──────────────────────────────────────────');
  for (final p in s['per_screen'] as List) {
    final mark = p['complete'] as bool ? '✓' : '⚠';
    print('  $mark ${p['screen']}: '
        'tested ${p['captured_pngs']} / mds ${p['mds_state_pngs']}');
  }
  final uncovered = s['uncovered_screens'] as List;
  if (uncovered.isNotEmpty) {
    print('');
    print('─── Uncovered MDS screens (${uncovered.length}) ──────────');
    for (final name in uncovered.take(10)) {
      print('  - $name');
    }
    if (uncovered.length > 10) {
      print('  ... +${uncovered.length - 10} more');
    }
  }
  final orphan = s['orphan_catalogs'] as List;
  if (orphan.isNotEmpty) {
    print('');
    print('─── Orphan catalogs (MDS 에 없음) ─────────────────────');
    for (final name in orphan) {
      print('  - $name');
    }
  }
}
