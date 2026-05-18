// CUJ tests — event / refund-policy-v2 (app_user)
//
// 대응 spec: docs/features/event/refund-policy-v2/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 본 파일은 이벤트 상세 페이지의 환불 정책 섹션(RefundPolicySection) CUJ를 검증:
//   - CUJ 2-2 (P1): 결제 전 환불 정책 안내 시트
//   - CUJ 2-3 (P1): 환불 정책 섹션 인라인 표시

import 'package:app_user/src/features/event/detail/event_detail_now_provider.dart';
import 'package:app_user/src/features/event/detail/event_refund_policy_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockPolicyRepository extends Mock implements PolicyRepository {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

/// Default refund policy matching spec (grace=3h, cutoff=7d).
Map<String, dynamic> _defaultPolicy() => {
  'grace_period_hours': 3,
  'cutoff_days': 7,
};

/// Event starting 14 days from now — cutoff (7d before start) is still 7 days away.
Event _futureEvent() {
  final start = DateTime.now().add(const Duration(days: 14));
  return Event(
    id: 'evt-1',
    partyId: 'party-1',
    startTime: start,
    endTime: start.add(const Duration(hours: 2)),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

/// Event starting 3 days from now — cutoff (7d before start) passed 4 days ago.
Event _soonEvent() {
  final start = DateTime.now().add(const Duration(days: 3));
  return Event(
    id: 'evt-2',
    partyId: 'party-1',
    startTime: start,
    endTime: start.add(const Duration(hours: 2)),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late _MockPolicyRepository mockPolicyRepo;

  setUp(() {
    mockPolicyRepo = _MockPolicyRepository();
    when(
      () => mockPolicyRepo.getRefundPolicy(),
    ).thenAnswer((_) async => _defaultPolicy());
  });

  List<dynamic> base() => [
    policyRepositoryProvider.overrideWith((_) => mockPolicyRepo),
  ];

  // =========================================================================
  // CUJ 2-2: 결제 전 환불 정책 안내 시트
  // =========================================================================

  cujGroup('2-2', '결제 전 환불 정책 안내 시트', () {
    cujCase(
      'happy: info 버튼 탭 → 환불 정책 상세 시트 (3개 조건 + 안내 텍스트)',
      app: RefundPolicySection(event: _futureEvent()),
      overrides: base,
      body: (t) async {
        // Info button is present
        final infoButton = find.byTooltip('환불 정책 상세');
        expect(infoButton, findsOneWidget);

        // Tap info button → modal bottom sheet appears
        await t.tap(infoButton);
        await t.pumpAndSettle();

        // FR-4: sheet title
        expect(find.text('환불 정책 상세'), findsOneWidget);
        // FR-4: 3 policy rows
        expect(find.textContaining('결제 후 3시간 이내'), findsAtLeast(1));
        expect(find.text('이벤트 시작 7일 전까지'), findsOneWidget);
        expect(find.text('그 외'), findsOneWidget);
        // FR-4: refund labels (2 rows = 2 widgets)
        expect(find.text('전액 환불'), findsNWidgets(2));
        // Fix #1140: "환불 불가" → "고객센터 문의" (대안 경로)
        expect(find.text('고객센터 문의'), findsOneWidget);
        // FR-4: footer note
        expect(find.text('자세한 내용은 고객센터로 문의해주세요.'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 정책 null → 기본값 (grace=2h, cutoff=7d) 으로 시트 표시',
      app: RefundPolicySection(event: _futureEvent()),
      overrides: () {
        final repo = _MockPolicyRepository();
        when(() => repo.getRefundPolicy()).thenAnswer((_) async => null);
        return [policyRepositoryProvider.overrideWith((_) => repo)];
      },
      body: (t) async {
        await t.tap(find.byTooltip('환불 정책 상세'));
        await t.pumpAndSettle();

        // Default grace = 2h when policy is null
        expect(find.textContaining('결제 후 2시간 이내'), findsAtLeast(1));
        expect(find.text('전액 환불'), findsAtLeast(1));
      },
    );
  });

  // =========================================================================
  // CUJ 2-3: 환불 정책 섹션 인라인 표시
  // =========================================================================

  cujGroup('2-3', '환불 정책 섹션 인라인 표시', () {
    cujCase(
      'happy: cutoff 전 이벤트 → 날짜 기반 환불 가능 배너 표시',
      app: RefundPolicySection(event: _futureEvent()),
      overrides: base,
      body: (t) async {
        // Fix #423: cutoff banner with check_circle icon
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        // "까지 환불 가능" text in cutoff banner
        expect(find.textContaining('까지 환불 가능'), findsOneWidget);
        // Sub-text: "결제 후 Xh 이내에도 전액 환불 가능"
        expect(find.textContaining('이내에도 전액 환불 가능'), findsOneWidget);
      },
    );

    cujCase(
      'happy: cutoff 경과 이벤트 → grace period 배너 + 마감 안내 표시',
      app: RefundPolicySection(event: _soonEvent()),
      overrides: base,
      body: (t) async {
        // Fix #423: grace period banner with schedule icon
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        // FR-4: "결제 후 Xh 이내 전액 환불 가능"
        expect(find.textContaining('결제 후 3시간 이내 전액 환불 가능'), findsOneWidget);
        // Sub-text: "이벤트 시작 Xd 전 환불 마감"
        expect(find.textContaining('전 환불 마감'), findsOneWidget);
      },
    );

    cujCase(
      'edge: cutoff date가 오늘 — "(오늘)" 라벨 표시',
      app: RefundPolicySection(event: _futureEvent()),
      overrides: () {
        // Override "now" to be exactly the cutoff date:
        // _futureEvent: startTime = now+14d → cutoff = now+7d
        final cutoffDate = DateTime.now().add(const Duration(days: 7));
        return [
          ...base(),
          eventDetailNowProvider.overrideWithValue(() => cutoffDate),
        ];
      },
      body: (t) async {
        // daysLeft = 0 → "(오늘)" label appended
        expect(find.textContaining('(오늘)'), findsOneWidget);
        expect(find.textContaining('까지 환불 가능'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 정책 로드 실패 → 기본값 폴백 (크래시 없음)',
      app: RefundPolicySection(event: _futureEvent()),
      overrides: () {
        final repo = _MockPolicyRepository();
        when(
          () => repo.getRefundPolicy(),
        ).thenThrow(Exception('network error'));
        return [policyRepositoryProvider.overrideWith((_) => repo)];
      },
      body: (t) async {
        // error path → _buildSummary(context, ref, null) with defaults
        // Default: grace=2h, cutoff=7d. Event is 14d from now → cutoff refundable.
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.textContaining('이내에도 전액 환불 가능'), findsOneWidget);
      },
    );
  });
}
