// _manifest.yaml 데이터 모델 + YAML 직렬화.
//
// 인스펙션 워크플로우가 MDS state index ↔ 캡처 PNG 페어링 시 사용.
//
// 출력 위치: docs/infra/mds-emulator-render/<screen>/_manifest.yaml
//
// 작성 주체: host 측 `scripts/mds_render_coverage.dart` 가 registry 의
// 모든 catalog 를 import 한 뒤 본 클래스로 직렬화 → 파일 쓰기.
// (driver 측 emulator 환경에서 작성 안 함 — catalog 메타데이터 접근 어려움)

/// 한 state 의 manifest entry.
class MdsManifestState {
  const MdsManifestState({
    required this.name,
    required this.mdsIndex,
    required this.tags,
  });

  final String name;
  final int? mdsIndex;
  final List<String> tags;
}

/// 한 화면 manifest.
class MdsManifest {
  const MdsManifest({
    required this.screen,
    required this.mdsSpec,
    required this.states,
  });

  final String screen;
  final String mdsSpec;
  final List<MdsManifestState> states;

  /// YAML 직렬화 (단순 — 외부 yaml 패키지 의존 없이).
  String toYaml({DateTime? generatedAt}) {
    final ts = (generatedAt ?? DateTime.now().toUtc()).toIso8601String();
    final buf = StringBuffer()
      ..writeln('schema: 1')
      ..writeln('screen: $screen')
      ..writeln('mds_spec: $mdsSpec')
      ..writeln('generated_at: $ts')
      ..writeln('states:');
    for (final s in states) {
      buf.writeln('  - name: ${s.name}');
      if (s.mdsIndex != null) buf.writeln('    mds_index: ${s.mdsIndex}');
      buf.writeln('    file: ${s.name}.png');
      if (s.tags.isNotEmpty) {
        buf.writeln('    tags: [${s.tags.join(', ')}]');
      }
    }
    return buf.toString();
  }
}
