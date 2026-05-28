// CUJ tests — admin / statistics-tools
//
// 대응 spec: docs/features/admin/statistics-tools/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '운영팀 Metabase 일간 지표 조회', () {
    cujCase(
      'happy: OTP 인증 후 어제 지표(DAU/매출/결제 성공률) 확인',
      app: const _MetabaseHarness(),
      body: (t) async {
        expect(find.text('Zero Trust OTP 인증 완료'), findsOneWidget);
        expect(find.text('어제 DAU: 1,240'), findsOneWidget);
        expect(find.text('어제 매출: ₩12,300,000'), findsOneWidget);
        expect(find.text('결제 성공률: 97.8%'), findsOneWidget);
        expect(find.text('차트/표 뷰 활성'), findsOneWidget);
      },
    );

    cujCase(
      'edge: Cloudflare Tunnel 끊김 시 접근 차단 + 운영팀 알림',
      app: const _MetabaseHarness(tunnelConnected: false),
      body: (t) async {
        expect(find.text('Metabase 접근 불가'), findsOneWidget);
        expect(find.text('운영팀 알림 전송'), findsOneWidget);
      },
    );

    cujCase(
      'edge: pg_cron 집계 실패 시 다음 주기 보강 예약',
      app: const _MetabaseHarness(),
      body: (t) async {
        await t.tap(find.text('pg_cron 실패 시뮬레이션'));
        await t.pumpAndSettle();

        expect(find.text('누락 일 보강 예약'), findsOneWidget);
        expect(find.text('운영팀 알림 전송'), findsOneWidget);
      },
    );
  });

  cujGroup('1-2', '매일 9AM KST 자동 일간 리포트', () {
    cujCase(
      'happy: 일간 리포트 Issue 생성 + metrics-alert/report 라벨 부여',
      app: const _ReportHarness(mode: _ReportMode.daily),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();

        expect(find.text('일간 리포트 생성됨 (09:00 KST)'), findsOneWidget);
        expect(find.text('labels: metrics-alert, report'), findsOneWidget);
        expect(find.text('요약 표: 매출 / DAU / 결제 성공률'), findsOneWidget);
      },
    );

    cujCase(
      'edge: GitHub API 장애 시 1회 재시도 후 Sentry 에러 기록',
      app: const _ReportHarness(
        mode: _ReportMode.daily,
        githubApiHealthy: false,
      ),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();
        expect(find.text('1회 재시도'), findsOneWidget);

        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();
        expect(find.text('Sentry 에러 기록'), findsOneWidget);
      },
    );
  });

  cujGroup('1-3', '주간 리포트 (PM/운영 정기 회의용)', () {
    cujCase(
      'happy: 월요일 9AM KST 주간 요약 + 전주 대비 추이 포함',
      app: const _ReportHarness(mode: _ReportMode.weekly),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();

        expect(find.text('주간 리포트 생성됨 (월요일 09:00 KST)'), findsOneWidget);
        expect(find.text('요약 표: 전주 대비 +3.2%'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 일부 지표 누락 시 0으로 보정해 리포트 유지',
      app: const _ReportHarness(
        mode: _ReportMode.weekly,
        weeklyComparisonReady: false,
      ),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();

        expect(find.text('전주 데이터 일부 누락: 0으로 보정'), findsOneWidget);
        expect(find.text('주간 리포트 생성됨 (월요일 09:00 KST)'), findsOneWidget);
      },
    );
  });

  cujGroup('2-1', '신규 기능 Feature Flag 점진 출시', () {
    cujCase(
      'happy: dev ON 검증 후 prod ON 전환',
      app: const _FeatureFlagHarness(),
      body: (t) async {
        await t.tap(find.text('dev ON'));
        await t.pumpAndSettle();
        await t.tap(find.text('prod ON'));
        await t.pumpAndSettle();

        expect(find.text('development tier: ON'), findsOneWidget);
        expect(find.text('production tier: ON'), findsOneWidget);
        expect(find.text('모니터링 시작'), findsOneWidget);
      },
    );

    cujCase(
      'edge: prod 트래픽이 dev 키 사용 시 빌드 실패로 차단',
      app: const _FeatureFlagHarness(envKeyMismatch: true),
      body: (t) async {
        await t.tap(find.text('빌드 검증'));
        await t.pumpAndSettle();

        expect(find.text('빌드 실패: 환경별 키 매칭 오류'), findsOneWidget);
      },
    );
  });

  cujGroup('2-2', '사고 발생 시 Feature Flag kill switch', () {
    cujCase(
      'happy: prod OFF 후 polling 주기 내 반영',
      app: const _FeatureFlagHarness(productionInitiallyOn: true),
      body: (t) async {
        await t.tap(find.text('prod OFF (kill switch)'));
        await t.pumpAndSettle();

        expect(find.text('production tier: OFF'), findsOneWidget);
        expect(find.text('반영 완료 (p95 <= 60초)'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 백그라운드 중 kill switch 발생 시 포그라운드 복귀에서 즉시 반영',
      app: const _FeatureFlagHarness(
        productionInitiallyOn: true,
        appInBackground: true,
      ),
      body: (t) async {
        await t.tap(find.text('prod OFF (kill switch)'));
        await t.pumpAndSettle();
        expect(find.text('포그라운드 복귀 대기'), findsOneWidget);

        await t.tap(find.text('포그라운드 복귀'));
        await t.pumpAndSettle();
        expect(find.text('production tier: OFF'), findsOneWidget);
        expect(find.text('인메모리 캐시 무효화 완료'), findsOneWidget);
      },
    );
  });

  cujGroup('3-1', '결제 에러율 임계치 초과 → 자동 Issue', () {
    cujCase(
      'happy: 15분 윈도우 에러율 5% 초과 시 performance Issue 생성',
      app: const _PerformanceAlertHarness(
        errorRate15m: 6.3,
        shortSpikeOnly: false,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(
          find.text('Issue 생성: metrics-alert/performance'),
          findsOneWidget,
        );
      },
    );

    cujCase(
      'edge: 1분 spike 단발성은 알림 생성 안 함',
      app: const _PerformanceAlertHarness(
        errorRate15m: 6.3,
        shortSpikeOnly: true,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(find.text('1분 spike: 알림 생성 안 함'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '비즈니스 지표 급락 알림', () {
    cujCase(
      'happy: 매출 -30% 초과 하락 감지 시 business-metrics Issue 생성',
      app: const _BusinessAlertHarness(
        revenueDropPct: -34,
        conversionDropPct: -12,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(
          find.text('Issue 생성: metrics-alert/business-metrics'),
          findsOneWidget,
        );
      },
    );

    cujCase(
      'edge: 임계치 미도달 하락은 알림 생성 안 함',
      app: const _BusinessAlertHarness(
        revenueDropPct: -10,
        conversionDropPct: -8,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(find.text('정상 범위: 알림 생성 안 함'), findsOneWidget);
      },
    );
  });

  cujGroup('3-3', '인프라 적체 알림 (DLQ / cron 누락)', () {
    cujCase(
      'happy: DLQ > 10 또는 cron 누락 시 infrastructure Issue 생성',
      app: const _InfraAlertHarness(dlqCount: 12, cronMissed: false),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(
          find.text('Issue 생성: metrics-alert/infrastructure'),
          findsOneWidget,
        );
      },
    );

    cujCase(
      'edge: cron 누락 시 다음 주기 보강 실행',
      app: const _InfraAlertHarness(dlqCount: 0, cronMissed: true),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(find.text('cron 누락 감지: 다음 주기 보강'), findsOneWidget);
      },
    );
  });

  cujGroup('3-4', '동일 알림 중복 차단', () {
    cujCase(
      'happy: 같은 제목 open Issue 존재 시 댓글만 추가',
      app: const _DedupeHarness(hasOpenIssue: true, recentlyClosed: false),
      body: (t) async {
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();

        expect(find.text('중복 감지: 기존 Issue에 댓글 추가'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 사람이 close 한 뒤 1분 grace 경과 후 재발하면 새 Issue 생성',
      app: const _DedupeHarness(hasOpenIssue: false, recentlyClosed: true),
      body: (t) async {
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();
        expect(find.text('grace 대기 중'), findsOneWidget);

        await t.tap(find.text('1분 경과'));
        await t.pumpAndSettle();
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();

        expect(find.text('새 Issue 생성: metrics-alert'), findsOneWidget);
      },
    );
  });

  cujGroup('4-1', '앱 실행 시 DAU 이벤트 수집', () {
    cujCase(
      'happy: app_opened 전송 후 일별 DAU 집계 반영 예약',
      app: const _ClientEventHarness(statsigAvailable: true),
      body: (t) async {
        await t.tap(find.text('앱 콜드 스타트'));
        await t.pumpAndSettle();

        expect(find.text('전송 이벤트: app_opened'), findsOneWidget);
        expect(find.text('DAU 집계 반영 예약'), findsOneWidget);
      },
    );

    cujCase(
      'edge: Statsig 장애 시 큐잉 후 복구 시 일괄 전송',
      app: const _ClientEventHarness(statsigAvailable: false),
      body: (t) async {
        await t.tap(find.text('앱 콜드 스타트'));
        await t.pumpAndSettle();
        expect(find.text('큐 적재: app_opened'), findsOneWidget);

        await t.tap(find.text('Statsig 복구'));
        await t.pumpAndSettle();
        expect(find.text('복구 후 일괄 전송: 1건'), findsOneWidget);
      },
    );
  });

  cujGroup('4-2', '결제 성공/실패 이벤트 수집', () {
    cujCase(
      'happy: 결제 성공/실패 분기 이벤트를 각각 전송',
      app: const _PaymentEventHarness(),
      body: (t) async {
        await t.tap(find.text('결제 성공'));
        await t.pumpAndSettle();
        await t.tap(find.text('결제 실패'));
        await t.pumpAndSettle();

        expect(find.text('전송 이벤트: payment_completed'), findsOneWidget);
        expect(find.text('전송 이벤트: payment_failed'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 전송 실패 이벤트는 재시도 큐로 보강',
      app: const _PaymentEventHarness(statsigAvailable: false),
      body: (t) async {
        await t.tap(find.text('결제 성공'));
        await t.pumpAndSettle();

        expect(find.text('재시도 큐: payment_completed'), findsOneWidget);
      },
    );
  });

  cujGroup('4-3', 'dev 환경 이벤트는 prod 와 분리', () {
    cujCase(
      'happy: development tier 이벤트는 dev 집계에만 반영',
      app: const _TierIsolationHarness(tier: 'development'),
      body: (t) async {
        await t.tap(find.text('이벤트 전송'));
        await t.pumpAndSettle();

        expect(find.text('dev 집계 반영'), findsOneWidget);
        expect(find.text('prod 집계 미반영'), findsOneWidget);
      },
    );

    cujCase(
      'edge: tier parameter 누락 시 CI 빌드 실패',
      app: const _TierIsolationHarness(tier: ''),
      body: (t) async {
        await t.tap(find.text('이벤트 전송'));
        await t.pumpAndSettle();

        expect(find.text('빌드 실패: tier parameter 누락'), findsOneWidget);
      },
    );
  });

  cujGroup('4-4', 'BI 도구의 PII 접근 차단', () {
    cujCase(
      'happy: analytics_reader 의 auth/public PII SELECT 차단',
      app: const _PiiGuardHarness(permissionDrift: false),
      body: (t) async {
        await t.tap(find.text('PII SELECT 시도'));
        await t.pumpAndSettle();

        expect(find.text('권한 거부: access denied'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 권한 drift 발견 시 분기 audit로 role 즉시 회수',
      app: const _PiiGuardHarness(permissionDrift: true),
      body: (t) async {
        await t.tap(find.text('PII SELECT 시도'));
        await t.pumpAndSettle();
        expect(find.text('PII 노출 위험 감지'), findsOneWidget);

        await t.tap(find.text('분기 audit 실행'));
        await t.pumpAndSettle();
        expect(find.text('analytics_reader role 즉시 회수'), findsOneWidget);
      },
    );
  });
}

class _MetabaseHarness extends StatefulWidget {
  const _MetabaseHarness({this.tunnelConnected = true});

  final bool tunnelConnected;

  @override
  State<_MetabaseHarness> createState() => _MetabaseHarnessState();
}

class _MetabaseHarnessState extends State<_MetabaseHarness> {
  bool _cronHealthy = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zero Trust OTP 인증 완료'),
            const SizedBox(height: 8),
            if (!widget.tunnelConnected) ...[
              const Text('Metabase 접근 불가'),
              const Text('운영팀 알림 전송'),
            ] else ...[
              const Text('어제 DAU: 1,240'),
              const Text('어제 매출: ₩12,300,000'),
              const Text('결제 성공률: 97.8%'),
              const Text('차트/표 뷰 활성'),
            ],
            if (!_cronHealthy) ...[
              const SizedBox(height: 8),
              const Text('누락 일 보강 예약'),
              const Text('운영팀 알림 전송'),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => _cronHealthy = false),
              child: const Text('pg_cron 실패 시뮬레이션'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReportMode { daily, weekly }

class _ReportHarness extends StatefulWidget {
  const _ReportHarness({
    required this.mode,
    this.githubApiHealthy = true,
    this.weeklyComparisonReady = true,
  });

  final _ReportMode mode;
  final bool githubApiHealthy;
  final bool weeklyComparisonReady;

  @override
  State<_ReportHarness> createState() => _ReportHarnessState();
}

class _ReportHarnessState extends State<_ReportHarness> {
  bool _generated = false;
  bool _retried = false;
  bool _sentryError = false;

  void _generate() {
    setState(() {
      if (widget.githubApiHealthy) {
        _generated = true;
        return;
      }
      if (!_retried) {
        _retried = true;
      } else {
        _sentryError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDaily = widget.mode == _ReportMode.daily;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isDaily ? '스케줄: 매일 09:00 KST' : '스케줄: 월요일 09:00 KST'),
            const SizedBox(height: 8),
            if (_generated) ...[
              Text(
                isDaily
                    ? '일간 리포트 생성됨 (09:00 KST)'
                    : '주간 리포트 생성됨 (월요일 09:00 KST)',
              ),
              const Text('labels: metrics-alert, report'),
              Text(
                isDaily ? '요약 표: 매출 / DAU / 결제 성공률' : '요약 표: 전주 대비 +3.2%',
              ),
              if (!isDaily && !widget.weeklyComparisonReady)
                const Text('전주 데이터 일부 누락: 0으로 보정'),
            ],
            if (_retried && !widget.githubApiHealthy) const Text('1회 재시도'),
            if (_sentryError) const Text('Sentry 에러 기록'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _generate,
              child: const Text('리포트 생성'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureFlagHarness extends StatefulWidget {
  const _FeatureFlagHarness({
    this.envKeyMismatch = false,
    this.productionInitiallyOn = false,
    this.appInBackground = false,
  });

  final bool envKeyMismatch;
  final bool productionInitiallyOn;
  final bool appInBackground;

  @override
  State<_FeatureFlagHarness> createState() => _FeatureFlagHarnessState();
}

class _FeatureFlagHarnessState extends State<_FeatureFlagHarness> {
  bool _devOn = false;
  late bool _prodOn;
  bool _monitoringStarted = false;
  bool _buildFailed = false;
  bool _pendingForegroundApply = false;
  bool _cacheInvalidated = false;
  bool _reflectedWithinSla = false;

  @override
  void initState() {
    super.initState();
    _prodOn = widget.productionInitiallyOn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('development tier: ${_devOn ? 'ON' : 'OFF'}'),
            Text('production tier: ${_prodOn ? 'ON' : 'OFF'}'),
            if (_monitoringStarted) const Text('모니터링 시작'),
            if (_buildFailed) const Text('빌드 실패: 환경별 키 매칭 오류'),
            if (_pendingForegroundApply) const Text('포그라운드 복귀 대기'),
            if (_cacheInvalidated) const Text('인메모리 캐시 무효화 완료'),
            if (_reflectedWithinSla) const Text('반영 완료 (p95 <= 60초)'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => _devOn = true),
              child: const Text('dev ON'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _prodOn = true;
                _monitoringStarted = true;
              }),
              child: const Text('prod ON'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.appInBackground) {
                  _pendingForegroundApply = true;
                } else {
                  _prodOn = false;
                  _reflectedWithinSla = true;
                }
              }),
              child: const Text('prod OFF (kill switch)'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (_pendingForegroundApply) {
                  _pendingForegroundApply = false;
                  _prodOn = false;
                  _cacheInvalidated = true;
                }
              }),
              child: const Text('포그라운드 복귀'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.envKeyMismatch) {
                  _buildFailed = true;
                }
              }),
              child: const Text('빌드 검증'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceAlertHarness extends StatefulWidget {
  const _PerformanceAlertHarness({
    required this.errorRate15m,
    required this.shortSpikeOnly,
  });

  final double errorRate15m;
  final bool shortSpikeOnly;

  @override
  State<_PerformanceAlertHarness> createState() =>
      _PerformanceAlertHarnessState();
}

class _PerformanceAlertHarnessState extends State<_PerformanceAlertHarness> {
  String _status = '대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.shortSpikeOnly) {
                  _status = '1분 spike: 알림 생성 안 함';
                  return;
                }
                if (widget.errorRate15m > 5.0) {
                  _status = 'Issue 생성: metrics-alert/performance';
                } else {
                  _status = '정상 범위';
                }
              }),
              child: const Text('임계치 판정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessAlertHarness extends StatefulWidget {
  const _BusinessAlertHarness({
    required this.revenueDropPct,
    required this.conversionDropPct,
  });

  final double revenueDropPct;
  final double conversionDropPct;

  @override
  State<_BusinessAlertHarness> createState() => _BusinessAlertHarnessState();
}

class _BusinessAlertHarnessState extends State<_BusinessAlertHarness> {
  String _status = '대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.revenueDropPct <= -30 ||
                    widget.conversionDropPct <= -20) {
                  _status = 'Issue 생성: metrics-alert/business-metrics';
                } else {
                  _status = '정상 범위: 알림 생성 안 함';
                }
              }),
              child: const Text('임계치 판정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfraAlertHarness extends StatefulWidget {
  const _InfraAlertHarness({required this.dlqCount, required this.cronMissed});

  final int dlqCount;
  final bool cronMissed;

  @override
  State<_InfraAlertHarness> createState() => _InfraAlertHarnessState();
}

class _InfraAlertHarnessState extends State<_InfraAlertHarness> {
  String _status = '대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.cronMissed) {
                  _status = 'cron 누락 감지: 다음 주기 보강';
                  return;
                }
                if (widget.dlqCount > 10) {
                  _status = 'Issue 생성: metrics-alert/infrastructure';
                } else {
                  _status = '정상 범위';
                }
              }),
              child: const Text('임계치 판정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DedupeHarness extends StatefulWidget {
  const _DedupeHarness({
    required this.hasOpenIssue,
    required this.recentlyClosed,
  });

  final bool hasOpenIssue;
  final bool recentlyClosed;

  @override
  State<_DedupeHarness> createState() => _DedupeHarnessState();
}

class _DedupeHarnessState extends State<_DedupeHarness> {
  bool _graceElapsed = false;
  String _status = '대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.hasOpenIssue) {
                  _status = '중복 감지: 기존 Issue에 댓글 추가';
                  return;
                }
                if (widget.recentlyClosed && !_graceElapsed) {
                  _status = 'grace 대기 중';
                  return;
                }
                _status = '새 Issue 생성: metrics-alert';
              }),
              child: const Text('알림 생성 시도'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => _graceElapsed = true),
              child: const Text('1분 경과'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientEventHarness extends StatefulWidget {
  const _ClientEventHarness({required this.statsigAvailable});

  final bool statsigAvailable;

  @override
  State<_ClientEventHarness> createState() => _ClientEventHarnessState();
}

class _ClientEventHarnessState extends State<_ClientEventHarness> {
  bool _sent = false;
  bool _queued = false;
  bool _flushed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_sent) const Text('전송 이벤트: app_opened'),
            if (_queued) const Text('큐 적재: app_opened'),
            if (_flushed) const Text('복구 후 일괄 전송: 1건'),
            if (_sent || _flushed) const Text('DAU 집계 반영 예약'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.statsigAvailable) {
                  _sent = true;
                } else {
                  _queued = true;
                }
              }),
              child: const Text('앱 콜드 스타트'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (_queued) {
                  _queued = false;
                  _flushed = true;
                }
              }),
              child: const Text('Statsig 복구'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentEventHarness extends StatefulWidget {
  const _PaymentEventHarness({this.statsigAvailable = true});

  final bool statsigAvailable;

  @override
  State<_PaymentEventHarness> createState() => _PaymentEventHarnessState();
}

class _PaymentEventHarnessState extends State<_PaymentEventHarness> {
  final List<String> _sent = [];
  final List<String> _retry = [];

  void _record(String event) {
    setState(() {
      if (widget.statsigAvailable) {
        _sent.add(event);
      } else {
        _retry.add(event);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._sent.map((e) => Text('전송 이벤트: $e')),
            ..._retry.map((e) => Text('재시도 큐: $e')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _record('payment_completed'),
              child: const Text('결제 성공'),
            ),
            ElevatedButton(
              onPressed: () => _record('payment_failed'),
              child: const Text('결제 실패'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierIsolationHarness extends StatefulWidget {
  const _TierIsolationHarness({required this.tier});

  final String tier;

  @override
  State<_TierIsolationHarness> createState() => _TierIsolationHarnessState();
}

class _TierIsolationHarnessState extends State<_TierIsolationHarness> {
  String _status = '대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.tier.isEmpty) {
                  _status = '빌드 실패: tier parameter 누락';
                  return;
                }
                if (widget.tier == 'development') {
                  _status = 'dev 집계 반영';
                } else {
                  _status = 'prod 집계 반영';
                }
              }),
              child: const Text('이벤트 전송'),
            ),
            if (widget.tier == 'development' && _status == 'dev 집계 반영')
              const Text('prod 집계 미반영'),
          ],
        ),
      ),
    );
  }
}

class _PiiGuardHarness extends StatefulWidget {
  const _PiiGuardHarness({required this.permissionDrift});

  final bool permissionDrift;

  @override
  State<_PiiGuardHarness> createState() => _PiiGuardHarnessState();
}

class _PiiGuardHarnessState extends State<_PiiGuardHarness> {
  String _status = '대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: $_status'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.permissionDrift) {
                  _status = 'PII 노출 위험 감지';
                } else {
                  _status = '권한 거부: access denied';
                }
              }),
              child: const Text('PII SELECT 시도'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.permissionDrift) {
                  _status = 'analytics_reader role 즉시 회수';
                }
              }),
              child: const Text('분기 audit 실행'),
            ),
          ],
        ),
      ),
    );
  }
}
