// CUJ tests — admin / statistics-tools
//
// 대응 spec: docs/features/admin/statistics-tools/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_user/src/features/admin/statistics_tools/ui/statistics_tools_contract_harness.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

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

    cujCase(
      'edge: pg_cron 집계 실패 시 다음 주기 보강 예약',
      app: MetabaseHarness(
        onSignal: (signal) {
          expect(signal.action, 'metabase.cron_failed');
          expect(signal.payload['recoveryScheduled'], true);
        },
      ),
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
      app: ReportHarness(
        mode: ReportMode.daily,
        onSignal: (signal) {
          expect(signal.action, 'report.created');
          expect(signal.payload['type'], 'report');
          expect(signal.payload['labels'], 'metrics-alert,report');
        },
      ),
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
      app: ReportHarness(
        mode: ReportMode.daily,
        githubApiHealthy: false,
        onSignal: (signal) {
          expect(
            signal.action == 'report.retry' ||
                signal.action == 'report.sentry_error',
            isTrue,
          );
        },
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
    cujCase(
      'happy: dev ON 검증 후 prod ON 전환',
      app: FeatureFlagHarness(
        onSignal: (signal) {
          expect(
            signal.action == 'flag.dev_on' || signal.action == 'flag.prod_on',
            isTrue,
          );
        },
      ),
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
      app: FeatureFlagHarness(
        envKeyMismatch: true,
        onSignal: (signal) {
          expect(signal.action, 'flag.build_validation_failed');
          expect(signal.payload['reason'], 'env_key_mismatch');
        },
      ),
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
      app: FeatureFlagHarness(
        productionInitiallyOn: true,
        onSignal: (signal) {
          expect(signal.action, 'flag.kill_switch_applied');
          expect(signal.payload['background'], false);
        },
      ),
      body: (t) async {
        await t.tap(find.text('prod OFF (kill switch)'));
        await t.pumpAndSettle();

        expect(find.text('production tier: OFF'), findsOneWidget);
        expect(find.text('반영 완료 (p95 <= 60초)'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 백그라운드 중 kill switch 발생 시 포그라운드 복귀에서 즉시 반영',
      app: FeatureFlagHarness(
        productionInitiallyOn: true,
        appInBackground: true,
        onSignal: (signal) {
          expect(
            signal.action == 'flag.kill_switch_pending' ||
                signal.action == 'flag.foreground_apply',
            isTrue,
          );
        },
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
      app: PerformanceAlertHarness(
        errorRate15m: 6.3,
        shortSpikeOnly: false,
        onSignal: (signal) {
          expect(signal.action, 'alert.created');
          expect(signal.payload['type'], 'performance');
        },
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
      app: PerformanceAlertHarness(
        errorRate15m: 6.3,
        shortSpikeOnly: true,
        onSignal: (signal) {
          expect(signal.action, 'alert.suppressed_short_spike');
        },
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
      app: BusinessAlertHarness(
        revenueDropPct: -34,
        conversionDropPct: -12,
        onSignal: (signal) {
          expect(signal.action, 'alert.created');
          expect(signal.payload['type'], 'business');
        },
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
    cujCase(
      'happy: DLQ > 10 또는 cron 누락 시 infrastructure Issue 생성',
      app: InfraAlertHarness(
        dlqCount: 12,
        cronMissed: false,
        onSignal: (signal) {
          expect(signal.action, 'alert.created');
          expect(signal.payload['type'], 'infra');
        },
      ),
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
      app: InfraAlertHarness(
        dlqCount: 0,
        cronMissed: true,
        onSignal: (signal) {
          expect(signal.action, 'alert.cron_recovery_scheduled');
        },
      ),
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
      app: DedupeHarness(
        hasOpenIssue: true,
        recentlyClosed: false,
        onSignal: (signal) {
          expect(signal.action, 'alert.commented_existing');
        },
      ),
      body: (t) async {
        await t.tap(find.text('알림 생성 시도'));
        await t.pumpAndSettle();

        expect(find.text('중복 감지: 기존 Issue에 댓글 추가'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 사람이 close 한 뒤 1분 grace 경과 후 재발하면 새 Issue 생성',
      app: DedupeHarness(
        hasOpenIssue: false,
        recentlyClosed: true,
        onSignal: (signal) {
          expect(
            signal.action == 'alert.grace_waiting' ||
                signal.action == 'alert.grace_elapsed' ||
                signal.action == 'alert.created_after_grace',
            isTrue,
          );
        },
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
      },
    );
  });

  cujGroup('4-1', '앱 실행 시 DAU 이벤트 수집', () {
    cujCase(
      'happy: app_opened 전송 후 일별 DAU 집계 반영 예약',
      app: ClientEventHarness(
        statsigAvailable: true,
        onSignal: (signal) {
          expect(signal.action, 'event.sent');
          expect(signal.payload['name'], 'app_opened');
        },
      ),
      body: (t) async {
        await t.tap(find.text('앱 콜드 스타트'));
        await t.pumpAndSettle();

        expect(find.text('전송 이벤트: app_opened'), findsOneWidget);
        expect(find.text('DAU 집계 반영 예약'), findsOneWidget);
      },
    );

    cujCase(
      'edge: Statsig 장애 시 큐잉 후 복구 시 일괄 전송',
      app: ClientEventHarness(
        statsigAvailable: false,
        onSignal: (signal) {
          expect(
            signal.action == 'event.queued' || signal.action == 'event.flushed',
            isTrue,
          );
        },
      ),
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
      app: PaymentEventHarness(
        onSignal: (signal) {
          expect(signal.action, 'event.sent');
        },
      ),
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
      app: PaymentEventHarness(
        statsigAvailable: false,
        onSignal: (signal) {
          expect(signal.action, 'event.queued');
          expect(signal.payload['name'], 'payment_completed');
        },
      ),
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
      app: TierIsolationHarness(
        tier: 'development',
        onSignal: (signal) {
          expect(signal.action, 'tier.dev_routed');
        },
      ),
      body: (t) async {
        await t.tap(find.text('이벤트 전송'));
        await t.pumpAndSettle();

        expect(find.text('dev 집계 반영'), findsOneWidget);
        expect(find.text('prod 집계 미반영'), findsOneWidget);
      },
    );

    cujCase(
      'edge: tier parameter 누락 시 CI 빌드 실패',
      app: TierIsolationHarness(
        tier: '',
        onSignal: (signal) {
          expect(signal.action, 'tier.validation_failed');
        },
      ),
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
      app: PiiGuardHarness(
        permissionDrift: false,
        onSignal: (signal) {
          expect(signal.action, 'pii.access_denied');
        },
      ),
      body: (t) async {
        await t.tap(find.text('PII SELECT 시도'));
        await t.pumpAndSettle();

        expect(find.text('권한 거부: access denied'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 권한 drift 발견 시 분기 audit로 role 즉시 회수',
      app: PiiGuardHarness(
        permissionDrift: true,
        onSignal: (signal) {
          expect(
            signal.action == 'pii.drift_detected' ||
                signal.action == 'pii.role_revoked',
            isTrue,
          );
        },
      ),
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
