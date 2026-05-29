// CUJ tests — admin / statistics-tools
//
// 대응 spec: docs/features/admin/statistics-tools/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_user/src/features/admin/statistics_tools/ui/statistics_tools_contract_harness.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

StatisticsToolsSignal _expectAction(
  List<StatisticsToolsSignal> signals,
  String action,
) {
  expect(
    signals.any((signal) => signal.action == action),
    isTrue,
    reason: [
      'expected action=$action',
      'actual=${signals.map((s) => s.action).toList()}',
    ].join(', '),
  );
  return signals.firstWhere((signal) => signal.action == action);
}

int _countAction(List<StatisticsToolsSignal> signals, String action) {
  return signals.where((signal) => signal.action == action).length;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '운영팀 Metabase 일간 지표 조회', () {
    cujCase(
      'happy: OTP 인증 후 어제 지표(DAU/매출/결제 성공률) 확인',
      app: const MetabaseHarness(),
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
      app: const MetabaseHarness(tunnelConnected: false),
      body: (t) async {
        expect(find.text('Metabase 접근 불가'), findsOneWidget);
        expect(find.text('운영팀 알림 전송'), findsOneWidget);
      },
    );

    final cronSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: pg_cron 집계 실패 시 다음 주기 보강 예약',
      app: MetabaseHarness(onSignal: cronSignals.add),
      body: (t) async {
        await t.tap(find.text('pg_cron 실패 시뮬레이션'));
        await t.pumpAndSettle();

        expect(find.text('누락 일 보강 예약'), findsOneWidget);
        expect(find.text('운영팀 알림 전송'), findsOneWidget);

        final failed = _expectAction(cronSignals, 'metabase.cron_failed');
        expect(failed.payload['recoveryScheduled'], true);
      },
    );
  });

  cujGroup('1-2', '매일 9AM KST 자동 일간 리포트', () {
    final dailyReportSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: 일간 리포트 Issue 생성 + metrics-alert/report 라벨 부여',
      app: ReportHarness(
        mode: ReportMode.daily,
        onSignal: dailyReportSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();

        expect(find.text('일간 리포트 생성됨 (09:00 KST)'), findsOneWidget);
        expect(find.text('labels: metrics-alert, report'), findsOneWidget);
        expect(find.text('요약 표: 매출 / DAU / 결제 성공률'), findsOneWidget);

        final created = _expectAction(dailyReportSignals, 'report.created');
        expect(created.payload['type'], 'report');
        expect(created.payload['labels'], 'metrics-alert,report');
      },
    );

    final dailyRetrySignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: GitHub API 장애 시 1회 재시도 후 Sentry 에러 기록',
      app: ReportHarness(
        mode: ReportMode.daily,
        githubApiHealthy: false,
        onSignal: dailyRetrySignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();
        expect(find.text('1회 재시도'), findsOneWidget);

        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();
        expect(find.text('Sentry 에러 기록'), findsOneWidget);

        _expectAction(dailyRetrySignals, 'report.retry');
        _expectAction(dailyRetrySignals, 'report.sentry_error');
      },
    );
  });

  cujGroup('1-3', '주간 리포트 (PM/운영 정기 회의용)', () {
    cujCase(
      'happy: 월요일 9AM KST 주간 요약 + 전주 대비 추이 포함',
      app: const ReportHarness(mode: ReportMode.weekly),
      body: (t) async {
        await t.tap(find.text('리포트 생성'));
        await t.pumpAndSettle();

        expect(find.text('주간 리포트 생성됨 (월요일 09:00 KST)'), findsOneWidget);
        expect(find.text('요약 표: 전주 대비 +3.2%'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 일부 지표 누락 시 0으로 보정해 리포트 유지',
      app: const ReportHarness(
        mode: ReportMode.weekly,
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
    final flagRolloutSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: dev ON 검증 후 prod ON 전환',
      app: FeatureFlagHarness(onSignal: flagRolloutSignals.add),
      body: (t) async {
        await t.tap(find.text('dev ON'));
        await t.pumpAndSettle();
        await t.tap(find.text('prod ON'));
        await t.pumpAndSettle();

        expect(find.text('development tier: ON'), findsOneWidget);
        expect(find.text('production tier: ON'), findsOneWidget);
        expect(find.text('모니터링 시작'), findsOneWidget);

        _expectAction(flagRolloutSignals, 'flag.dev_on');
        _expectAction(flagRolloutSignals, 'flag.prod_on');
      },
    );

    final envKeySignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: prod 트래픽이 dev 키 사용 시 빌드 실패로 차단',
      app: FeatureFlagHarness(
        envKeyMismatch: true,
        onSignal: envKeySignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('빌드 검증'));
        await t.pumpAndSettle();

        expect(find.text('빌드 실패: 환경별 키 매칭 오류'), findsOneWidget);

        final failed = _expectAction(
          envKeySignals,
          'flag.build_validation_failed',
        );
        expect(failed.payload['reason'], 'env_key_mismatch');
      },
    );
  });

  cujGroup('2-2', '사고 발생 시 Feature Flag kill switch', () {
    final killSwitchSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: prod OFF 후 polling 주기 내 반영',
      app: FeatureFlagHarness(
        productionInitiallyOn: true,
        onSignal: killSwitchSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('prod OFF (kill switch)'));
        await t.pumpAndSettle();

        expect(find.text('production tier: OFF'), findsOneWidget);
        expect(find.text('반영 완료 (p95 <= 60초)'), findsOneWidget);

        final applied = _expectAction(
          killSwitchSignals,
          'flag.kill_switch_applied',
        );
        expect(applied.payload['background'], false);
      },
    );

    final backgroundKillSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: 백그라운드 중 kill switch 발생 시 포그라운드 복귀에서 즉시 반영',
      app: FeatureFlagHarness(
        productionInitiallyOn: true,
        appInBackground: true,
        onSignal: backgroundKillSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('prod OFF (kill switch)'));
        await t.pumpAndSettle();
        expect(find.text('포그라운드 복귀 대기'), findsOneWidget);

        await t.tap(find.text('포그라운드 복귀'));
        await t.pumpAndSettle();
        expect(find.text('production tier: OFF'), findsOneWidget);
        expect(find.text('인메모리 캐시 무효화 완료'), findsOneWidget);

        _expectAction(backgroundKillSignals, 'flag.kill_switch_pending');
        _expectAction(backgroundKillSignals, 'flag.foreground_apply');
      },
    );
  });

  cujGroup('3-1', '결제 에러율 임계치 초과 → 자동 Issue', () {
    final perfAlertSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: 15분 윈도우 에러율 5% 초과 시 performance Issue 생성',
      app: PerformanceAlertHarness(
        errorRate15m: 6.3,
        shortSpikeOnly: false,
        onSignal: perfAlertSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(
          find.text('Issue 생성: metrics-alert/performance'),
          findsOneWidget,
        );

        final created = _expectAction(perfAlertSignals, 'alert.created');
        expect(created.payload['type'], 'performance');
      },
    );

    final perfSuppressedSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: 1분 spike 단발성은 알림 생성 안 함',
      app: PerformanceAlertHarness(
        errorRate15m: 6.3,
        shortSpikeOnly: true,
        onSignal: perfSuppressedSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(find.text('1분 spike: 알림 생성 안 함'), findsOneWidget);
        _expectAction(perfSuppressedSignals, 'alert.suppressed_short_spike');
      },
    );
  });

  cujGroup('3-2', '비즈니스 지표 급락 알림', () {
    final businessAlertSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: 매출 -30% 초과 하락 감지 시 business-metrics Issue 생성',
      app: BusinessAlertHarness(
        revenueDropPct: -34,
        conversionDropPct: -12,
        onSignal: businessAlertSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(
          find.text('Issue 생성: metrics-alert/business-metrics'),
          findsOneWidget,
        );

        final created = _expectAction(businessAlertSignals, 'alert.created');
        expect(created.payload['type'], 'business');
      },
    );

    cujCase(
      'edge: 임계치 미도달 하락은 알림 생성 안 함',
      app: const BusinessAlertHarness(
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
    final infraAlertSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: DLQ > 10 또는 cron 누락 시 infrastructure Issue 생성',
      app: InfraAlertHarness(
        dlqCount: 12,
        cronMissed: false,
        onSignal: infraAlertSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(
          find.text('Issue 생성: metrics-alert/infrastructure'),
          findsOneWidget,
        );

        final created = _expectAction(infraAlertSignals, 'alert.created');
        expect(created.payload['type'], 'infra');
      },
    );

    final cronRecoverySignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: cron 누락 시 다음 주기 보강 실행',
      app: InfraAlertHarness(
        dlqCount: 0,
        cronMissed: true,
        onSignal: cronRecoverySignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('임계치 판정'));
        await t.pumpAndSettle();

        expect(find.text('cron 누락 감지: 다음 주기 보강'), findsOneWidget);
        _expectAction(cronRecoverySignals, 'alert.cron_recovery_scheduled');
      },
    );
  });

  cujGroup('3-4', '동일 알림 중복 차단', () {
    final dedupeSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: 같은 제목 open Issue 존재 시 댓글만 추가',
      app: DedupeHarness(
        hasOpenIssue: true,
        recentlyClosed: false,
        onSignal: dedupeSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();

        expect(find.text('중복 감지: 기존 Issue에 댓글 추가'), findsOneWidget);
        _expectAction(dedupeSignals, 'alert.commented_existing');
      },
    );

    final graceSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: 사람이 close 한 뒤 1분 grace 경과 후 재발하면 새 Issue 생성',
      app: DedupeHarness(
        hasOpenIssue: false,
        recentlyClosed: true,
        onSignal: graceSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();
        expect(find.text('grace 대기 중'), findsOneWidget);

        await t.tap(find.text('1분 경과'));
        await t.pumpAndSettle();
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();

        expect(find.text('새 Issue 생성: metrics-alert'), findsOneWidget);
        _expectAction(graceSignals, 'alert.grace_waiting');
        _expectAction(graceSignals, 'alert.grace_elapsed');
        _expectAction(graceSignals, 'alert.created_after_grace');
      },
    );
  });

  cujGroup('4-1', '앱 실행 시 DAU 이벤트 수집', () {
    final dauSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: app_opened 전송 후 일별 DAU 집계 반영 예약',
      app: ClientEventHarness(
        statsigAvailable: true,
        onSignal: dauSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('앱 콜드 스타트'));
        await t.pumpAndSettle();

        expect(find.text('전송 이벤트: app_opened'), findsOneWidget);
        expect(find.text('DAU 집계 반영 예약'), findsOneWidget);

        final sent = _expectAction(dauSignals, 'event.sent');
        expect(sent.payload['name'], 'app_opened');
      },
    );

    final queuedSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: Statsig 장애 시 큐잉 후 복구 시 일괄 전송',
      app: ClientEventHarness(
        statsigAvailable: false,
        onSignal: queuedSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('앱 콜드 스타트'));
        await t.pumpAndSettle();
        expect(find.text('큐 적재: app_opened'), findsOneWidget);

        await t.tap(find.text('Statsig 복구'));
        await t.pumpAndSettle();
        expect(find.text('복구 후 일괄 전송: 1건'), findsOneWidget);

        _expectAction(queuedSignals, 'event.queued');
        _expectAction(queuedSignals, 'event.flushed');
      },
    );
  });

  cujGroup('4-2', '결제 성공/실패 이벤트 수집', () {
    final paymentSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: 결제 성공/실패 분기 이벤트를 각각 전송',
      app: PaymentEventHarness(onSignal: paymentSignals.add),
      body: (t) async {
        await t.tap(find.text('결제 성공'));
        await t.pumpAndSettle();
        await t.tap(find.text('결제 실패'));
        await t.pumpAndSettle();

        expect(find.text('전송 이벤트: payment_completed'), findsOneWidget);
        expect(find.text('전송 이벤트: payment_failed'), findsOneWidget);
        expect(_countAction(paymentSignals, 'event.sent'), 2);
      },
    );

    final paymentRetrySignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: 전송 실패 이벤트는 재시도 큐로 보강',
      app: PaymentEventHarness(
        statsigAvailable: false,
        onSignal: paymentRetrySignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('결제 성공'));
        await t.pumpAndSettle();

        expect(find.text('재시도 큐: payment_completed'), findsOneWidget);

        final queued = _expectAction(paymentRetrySignals, 'event.queued');
        expect(queued.payload['name'], 'payment_completed');
      },
    );
  });

  cujGroup('4-3', 'dev 환경 이벤트는 prod 와 분리', () {
    final tierSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: development tier 이벤트는 dev 집계에만 반영',
      app: TierIsolationHarness(
        tier: 'development',
        onSignal: tierSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('이벤트 전송'));
        await t.pumpAndSettle();

        expect(find.text('dev 집계 반영'), findsOneWidget);
        expect(find.text('prod 집계 미반영'), findsOneWidget);

        _expectAction(tierSignals, 'tier.dev_routed');
      },
    );

    final tierValidationSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: tier parameter 누락 시 CI 빌드 실패',
      app: TierIsolationHarness(tier: '', onSignal: tierValidationSignals.add),
      body: (t) async {
        await t.tap(find.text('이벤트 전송'));
        await t.pumpAndSettle();

        expect(find.text('빌드 실패: tier parameter 누락'), findsOneWidget);
        _expectAction(tierValidationSignals, 'tier.validation_failed');
      },
    );
  });

  cujGroup('4-4', 'BI 도구의 PII 접근 차단', () {
    final piiGuardSignals = <StatisticsToolsSignal>[];
    cujCase(
      'happy: analytics_reader 의 auth/public PII SELECT 차단',
      app: PiiGuardHarness(
        permissionDrift: false,
        onSignal: piiGuardSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('PII SELECT 시도'));
        await t.pumpAndSettle();

        expect(find.text('권한 거부: access denied'), findsOneWidget);
        _expectAction(piiGuardSignals, 'pii.access_denied');
      },
    );

    final piiDriftSignals = <StatisticsToolsSignal>[];
    cujCase(
      'edge: 권한 drift 발견 시 분기 audit로 role 즉시 회수',
      app: PiiGuardHarness(
        permissionDrift: true,
        onSignal: piiDriftSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('PII SELECT 시도'));
        await t.pumpAndSettle();
        expect(find.text('PII 노출 위험 감지'), findsOneWidget);

        await t.tap(find.text('분기 audit 실행'));
        await t.pumpAndSettle();
        expect(find.text('analytics_reader role 즉시 회수'), findsOneWidget);

        _expectAction(piiDriftSignals, 'pii.drift_detected');
        _expectAction(piiDriftSignals, 'pii.role_revoked');
      },
    );
  });
}
