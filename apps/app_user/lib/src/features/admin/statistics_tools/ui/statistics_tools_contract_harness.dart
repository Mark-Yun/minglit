import 'package:flutter/material.dart';

class StatisticsToolsSignal {
  const StatisticsToolsSignal({required this.action, this.payload = const {}});

  final String action;
  final Map<String, Object?> payload;
}

typedef StatisticsToolsSignalSink = void Function(StatisticsToolsSignal signal);

enum ReportMode { daily, weekly }

class MetabaseHarness extends StatefulWidget {
  const MetabaseHarness({
    super.key,
    this.tunnelConnected = true,
    this.onSignal,
  });

  final bool tunnelConnected;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<MetabaseHarness> createState() => _MetabaseHarnessState();
}

class _MetabaseHarnessState extends State<MetabaseHarness> {
  bool _cronHealthy = true;

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
              onPressed: () => setState(() {
                _cronHealthy = false;
                _emit('metabase.cron_failed', {'recoveryScheduled': true});
              }),
              child: const Text('pg_cron 실패 시뮬레이션'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportHarness extends StatefulWidget {
  const ReportHarness({
    required this.mode, super.key,
    this.githubApiHealthy = true,
    this.weeklyComparisonReady = true,
    this.onSignal,
  });

  final ReportMode mode;
  final bool githubApiHealthy;
  final bool weeklyComparisonReady;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<ReportHarness> createState() => _ReportHarnessState();
}

class _ReportHarnessState extends State<ReportHarness> {
  bool _generated = false;
  bool _retried = false;
  bool _sentryError = false;

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

  void _generate() {
    setState(() {
      final cadence = widget.mode == ReportMode.daily ? 'daily' : 'weekly';
      if (widget.githubApiHealthy) {
        _generated = true;
        _emit('report.created', {
          'type': 'report',
          'cadence': cadence,
          'labels': 'metrics-alert,report',
        });
        return;
      }
      if (!_retried) {
        _retried = true;
        _emit('report.retry', {'attempt': 1, 'cadence': cadence});
      } else {
        _sentryError = true;
        _emit('report.sentry_error', {'cadence': cadence});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDaily = widget.mode == ReportMode.daily;
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

class FeatureFlagHarness extends StatefulWidget {
  const FeatureFlagHarness({
    super.key,
    this.envKeyMismatch = false,
    this.productionInitiallyOn = false,
    this.appInBackground = false,
    this.onSignal,
  });

  final bool envKeyMismatch;
  final bool productionInitiallyOn;
  final bool appInBackground;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<FeatureFlagHarness> createState() => _FeatureFlagHarnessState();
}

class _FeatureFlagHarnessState extends State<FeatureFlagHarness> {
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

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
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
              onPressed: () => setState(() {
                _devOn = true;
                _emit('flag.dev_on', {'tier': 'development'});
              }),
              child: const Text('dev ON'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _prodOn = true;
                _monitoringStarted = true;
                _emit('flag.prod_on', {'tier': 'production'});
              }),
              child: const Text('prod ON'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.appInBackground) {
                  _pendingForegroundApply = true;
                  _emit('flag.kill_switch_pending', {'background': true});
                } else {
                  _prodOn = false;
                  _reflectedWithinSla = true;
                  _emit('flag.kill_switch_applied', {'background': false});
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
                  _emit('flag.foreground_apply', {'cacheInvalidated': true});
                }
              }),
              child: const Text('포그라운드 복귀'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.envKeyMismatch) {
                  _buildFailed = true;
                  _emit('flag.build_validation_failed', {
                    'reason': 'env_key_mismatch',
                  });
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

class PerformanceAlertHarness extends StatefulWidget {
  const PerformanceAlertHarness({
    required this.errorRate15m, required this.shortSpikeOnly, super.key,
    this.onSignal,
  });

  final double errorRate15m;
  final bool shortSpikeOnly;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<PerformanceAlertHarness> createState() =>
      _PerformanceAlertHarnessState();
}

class _PerformanceAlertHarnessState extends State<PerformanceAlertHarness> {
  String _status = '대기';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('alert.suppressed_short_spike');
                  return;
                }
                if (widget.errorRate15m > 5.0) {
                  _status = 'Issue 생성: metrics-alert/performance';
                  _emit('alert.created', {'type': 'performance'});
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

class BusinessAlertHarness extends StatefulWidget {
  const BusinessAlertHarness({
    required this.revenueDropPct, required this.conversionDropPct, super.key,
    this.onSignal,
  });

  final double revenueDropPct;
  final double conversionDropPct;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<BusinessAlertHarness> createState() => _BusinessAlertHarnessState();
}

class _BusinessAlertHarnessState extends State<BusinessAlertHarness> {
  String _status = '대기';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('alert.created', {'type': 'business'});
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

class InfraAlertHarness extends StatefulWidget {
  const InfraAlertHarness({
    required this.dlqCount, required this.cronMissed, super.key,
    this.onSignal,
  });

  final int dlqCount;
  final bool cronMissed;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<InfraAlertHarness> createState() => _InfraAlertHarnessState();
}

class _InfraAlertHarnessState extends State<InfraAlertHarness> {
  String _status = '대기';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('alert.cron_recovery_scheduled');
                  return;
                }
                if (widget.dlqCount > 10) {
                  _status = 'Issue 생성: metrics-alert/infrastructure';
                  _emit('alert.created', {'type': 'infra'});
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

class DedupeHarness extends StatefulWidget {
  const DedupeHarness({
    required this.hasOpenIssue, required this.recentlyClosed, super.key,
    this.onSignal,
  });

  final bool hasOpenIssue;
  final bool recentlyClosed;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<DedupeHarness> createState() => _DedupeHarnessState();
}

class _DedupeHarnessState extends State<DedupeHarness> {
  bool _graceElapsed = false;
  String _status = '대기';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('alert.commented_existing');
                  return;
                }
                if (widget.recentlyClosed && !_graceElapsed) {
                  _status = 'grace 대기 중';
                  _emit('alert.grace_waiting');
                  return;
                }
                _status = '새 Issue 생성: metrics-alert';
                _emit('alert.created_after_grace');
              }),
              child: const Text('알림 생성 시도'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _graceElapsed = true;
                _emit('alert.grace_elapsed');
              }),
              child: const Text('1분 경과'),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientEventHarness extends StatefulWidget {
  const ClientEventHarness({
    required this.statsigAvailable, super.key,
    this.onSignal,
  });

  final bool statsigAvailable;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<ClientEventHarness> createState() => _ClientEventHarnessState();
}

class _ClientEventHarnessState extends State<ClientEventHarness> {
  bool _sent = false;
  bool _queued = false;
  bool _flushed = false;

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('event.sent', {'name': 'app_opened'});
                } else {
                  _queued = true;
                  _emit('event.queued', {'name': 'app_opened'});
                }
              }),
              child: const Text('앱 콜드 스타트'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (_queued) {
                  _queued = false;
                  _flushed = true;
                  _emit('event.flushed', {'count': 1});
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

class PaymentEventHarness extends StatefulWidget {
  const PaymentEventHarness({
    super.key,
    this.statsigAvailable = true,
    this.onSignal,
  });

  final bool statsigAvailable;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<PaymentEventHarness> createState() => _PaymentEventHarnessState();
}

class _PaymentEventHarnessState extends State<PaymentEventHarness> {
  final List<String> _sent = [];
  final List<String> _retry = [];

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

  void _record(String event) {
    setState(() {
      if (widget.statsigAvailable) {
        _sent.add(event);
        _emit('event.sent', {'name': event});
      } else {
        _retry.add(event);
        _emit('event.queued', {'name': event});
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

class TierIsolationHarness extends StatefulWidget {
  const TierIsolationHarness({
    required this.tier, super.key,
    this.onSignal,
  });

  final String tier;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<TierIsolationHarness> createState() => _TierIsolationHarnessState();
}

class _TierIsolationHarnessState extends State<TierIsolationHarness> {
  String _status = '대기';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('tier.validation_failed');
                  return;
                }
                if (widget.tier == 'development') {
                  _status = 'dev 집계 반영';
                  _emit('tier.dev_routed');
                } else {
                  _status = 'prod 집계 반영';
                  _emit('tier.prod_routed');
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

class PiiGuardHarness extends StatefulWidget {
  const PiiGuardHarness({
    required this.permissionDrift, super.key,
    this.onSignal,
  });

  final bool permissionDrift;
  final StatisticsToolsSignalSink? onSignal;

  @override
  State<PiiGuardHarness> createState() => _PiiGuardHarnessState();
}

class _PiiGuardHarnessState extends State<PiiGuardHarness> {
  String _status = '대기';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      StatisticsToolsSignal(action: action, payload: payload),
    );
  }

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
                  _emit('pii.drift_detected');
                } else {
                  _status = '권한 거부: access denied';
                  _emit('pii.access_denied');
                }
              }),
              child: const Text('PII SELECT 시도'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.permissionDrift) {
                  _status = 'analytics_reader role 즉시 회수';
                  _emit('pii.role_revoked');
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
