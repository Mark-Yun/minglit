#!/usr/bin/env dart
// CUJ coverage reconciler.
//
// 파일시스템만 스캔 (Flutter SDK / dart import 의존 없음):
//   - Spec: docs/features/<category>/<feature>/spec.md 의 CUJ 테이블
//   - Test: apps/{app_user,app_partner}/integration_test/cuj/<category>/<feature>_test.dart
//          의 `cujGroup('<id>', ...)` 호출
//
// feature 폴더명 dash → 테스트 파일명 underscore 매핑.
// (예: docs/features/account/signup-consent ↔
//      apps/app_user/integration_test/cuj/account/signup_consent_test.dart)
//
// 사용:
//   dart run scripts/cuj_coverage.dart           # 사람 친화 출력
//   dart run scripts/cuj_coverage.dart --json    # JSON
//
// 종료 코드:
//   0 — 100% CUJ 커버 + orphan 0
//   1 — 부족 (uncovered CUJ 또는 orphan test 존재)
//   2 — 스크립트 자체 에러

import 'dart:convert';
import 'dart:io';

const _specsRoot = 'docs/features';
const _testsRoots = [
  'apps/app_user/integration_test/cuj',
  'apps/app_partner/integration_test/cuj',
];

// spec.md CUJ row: `| 1-1 | P0 | name | ... |`
// 헤더(`| ID | ...`)와 separator(`|---|`)는 ID 가 `\d+-\d+` 패턴이 아니라 자동 제외.
final _cujRowPattern = RegExp(
  r'^\|\s*(\d+-\d+)\s*\|\s*(P\d)\s*\|\s*([^|]+?)\s*\|',
  multiLine: true,
);

// test 파일의 `cujGroup('1-1', '...', ...)` 호출
final _cujGroupPattern = RegExp(r"cujGroup\(\s*'(\d+-\d+)'");

class FeatureCoverage {
  FeatureCoverage(this.category, this.feature);

  final String category;
  final String feature;
  final List<Map<String, String>> specCujs = [];
  final Set<String> testedCujs = {};
  String? testFile;

  Set<String> get specIds => specCujs.map((c) => c['id']!).toSet();
  Set<String> get uncovered => specIds.difference(testedCujs);
  Set<String> get orphan => testedCujs.difference(specIds);
  int get coveredCount => specIds.intersection(testedCujs).length;
}

void main(List<String> args) {
  try {
    final json = args.contains('--json');

    // 1. Spec 스캔
    final features = <String, FeatureCoverage>{};
    for (final category in _listDirs(_specsRoot)) {
      final catPath = '$_specsRoot/$category';
      for (final feature in _listDirs(catPath)) {
        if (feature.startsWith('_')) continue;
        final specPath = '$catPath/$feature/spec.md';
        if (!File(specPath).existsSync()) continue;
        final cov = FeatureCoverage(category, feature);
        _parseSpec(specPath, cov);
        features['$category/$feature'] = cov;
      }
    }

    // 2. Test 스캔 (양 app)
    for (final testRoot in _testsRoots) {
      if (!Directory(testRoot).existsSync()) continue;
      for (final category in _listDirs(testRoot)) {
        if (category.startsWith('_')) continue;
        final catDir = Directory('$testRoot/$category');
        for (final entry in catDir.listSync()) {
          if (entry is! File) continue;
          final filename = entry.uri.pathSegments.last;
          if (!filename.endsWith('_test.dart')) continue;
          final testFeatureUnderscore =
              filename.substring(0, filename.length - '_test.dart'.length);

          // feature dir (dash) ↔ test filename (underscore) 매핑
          final match = features.values.firstWhere(
            (f) =>
                f.category == category &&
                f.feature.replaceAll('-', '_') == testFeatureUnderscore,
            orElse: () {
              final orphan = FeatureCoverage(
                category,
                '_orphan_$testFeatureUnderscore',
              );
              features['$category/${orphan.feature}'] = orphan;
              return orphan;
            },
          );
          match.testFile = entry.path;
          _parseTest(entry.path, match);
        }
      }
    }

    // 3. 집계
    var totalSpec = 0;
    var totalCovered = 0;
    final uncoveredList = <Map<String, dynamic>>[];
    final orphanList = <Map<String, dynamic>>[];

    final sortedKeys = features.keys.toList()..sort();
    for (final key in sortedKeys) {
      final f = features[key]!;
      totalSpec += f.specIds.length;
      totalCovered += f.coveredCount;
      if (f.uncovered.isNotEmpty) {
        uncoveredList.add({
          'category': f.category,
          'feature': f.feature,
          'uncovered': f.uncovered.toList()..sort(),
        });
      }
      if (f.orphan.isNotEmpty) {
        orphanList.add({
          'category': f.category,
          'feature': f.feature,
          'orphan': f.orphan.toList()..sort(),
        });
      }
    }

    final pct = totalSpec == 0 ? 100.0 : (totalCovered / totalSpec) * 100;

    final summary = {
      'spec_cujs': totalSpec,
      'covered_cujs': totalCovered,
      'coverage_pct': pct.toStringAsFixed(1),
      'uncovered_features': uncoveredList,
      'orphan_features': orphanList,
      'per_feature': sortedKeys.map((k) {
        final f = features[k]!;
        return {
          'category': f.category,
          'feature': f.feature,
          'spec': f.specIds.length,
          'tested': f.coveredCount,
          'has_test_file': f.testFile != null,
          'uncovered': f.uncovered.toList()..sort(),
          'orphan': f.orphan.toList()..sort(),
        };
      }).toList(),
    };

    if (json) {
      print(const JsonEncoder.withIndent('  ').convert(summary));
    } else {
      _printHuman(summary);
    }

    // pass: uncovered 0 + orphan 0
    final pass = uncoveredList.isEmpty && orphanList.isEmpty;
    exit(pass ? 0 : 1);
  } catch (e, st) {
    stderr.writeln('[cuj-coverage] error: $e\n$st');
    exit(2);
  }
}

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

void _parseSpec(String specPath, FeatureCoverage cov) {
  final content = File(specPath).readAsStringSync();
  for (final m in _cujRowPattern.allMatches(content)) {
    cov.specCujs.add({
      'id': m.group(1)!,
      'priority': m.group(2)!,
      'name': m.group(3)!.trim(),
    });
  }
}

void _parseTest(String testPath, FeatureCoverage cov) {
  final content = File(testPath).readAsStringSync();
  for (final m in _cujGroupPattern.allMatches(content)) {
    cov.testedCujs.add(m.group(1)!);
  }
}

void _printHuman(Map<String, dynamic> s) {
  print('═' * 60);
  print('  CUJ Coverage');
  print('═' * 60);
  print('  CUJs : ${s['covered_cujs']}/${s['spec_cujs']} (${s['coverage_pct']}%)');
  print('');
  print('─── Per-feature ─────────────────────────────────────────');
  for (final f in s['per_feature'] as List) {
    final mark = (f['uncovered'] as List).isEmpty &&
            (f['orphan'] as List).isEmpty &&
            (f['spec'] as int) > 0
        ? '✓'
        : '⚠';
    final testMark = f['has_test_file'] as bool ? '' : ' (no test file)';
    print(
        '  $mark ${f['category']}/${f['feature']}: ${f['tested']}/${f['spec']}$testMark');
  }
  final uncov = s['uncovered_features'] as List;
  if (uncov.isNotEmpty) {
    print('');
    print('─── Uncovered CUJs ──────────────────────────────────────');
    for (final f in uncov) {
      print('  - ${f['category']}/${f['feature']}: '
          '${(f['uncovered'] as List).join(', ')}');
    }
  }
  final orphan = s['orphan_features'] as List;
  if (orphan.isNotEmpty) {
    print('');
    print('─── Orphan test CUJs (spec 에 없음) ──────────────────');
    for (final f in orphan) {
      print('  - ${f['category']}/${f['feature']}: '
          '${(f['orphan'] as List).join(', ')}');
    }
  }
}
