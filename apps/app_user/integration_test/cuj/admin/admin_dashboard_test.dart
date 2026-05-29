// CUJ tests — admin / admin-dashboard
//
// 대응 spec: docs/features/admin/admin-dashboard/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

class AdminDashboardSignal {
  const AdminDashboardSignal({required this.action, this.payload = const {}});

  final String action;
  final Map<String, Object?> payload;
}

typedef AdminDashboardSignalSink = void Function(AdminDashboardSignal signal);

AdminDashboardSignal _expectAction(
  List<AdminDashboardSignal> signals,
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '운영자가 심사 큐에서 신청 진입', () {
    cujCase(
      'happy: 대기 summary 클릭 후 카드 목록 확인',
      app: const PartnerReviewQueueHarness(),
      body: (t) async {
        await t.tap(find.text('대기'));
        await t.pumpAndSettle();

        expect(find.text('심사 카드: 서울라운지'), findsOneWidget);
        expect(find.text('우선순위: 높음'), findsOneWidget);
        expect(find.text('사업자번호: 123-45-67890'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 심사 큐 0건이면 빈 상태 메시지 노출',
      app: const PartnerReviewQueueHarness(hasPending: false),
      body: (t) async {
        await t.tap(find.text('대기'));
        await t.pumpAndSettle();

        expect(find.text('처리할 심사 건이 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('1-2', '심사 상세에서 서류 검토 + 승인', () {
    final approvalSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 서류 검토 후 승인 + 감사 로그 기록',
      app: PartnerReviewQueueHarness(onSignal: approvalSignals.add),
      body: (t) async {
        await t.tap(find.text('대기'));
        await t.pumpAndSettle();
        await t.tap(find.text('심사 상세 진입'));
        await t.pumpAndSettle();

        expect(find.text('사업자등록증 미리보기'), findsOneWidget);
        expect(find.text('대표자 신분증 미리보기'), findsOneWidget);

        await t.enterText(find.byKey(const Key('review-comment')), '서류 확인 완료');
        await t.tap(find.text('승인'));
        await t.pumpAndSettle();

        expect(find.text('신청 상태: 승인'), findsOneWidget);
        expect(find.text('파트너 통보 전송'), findsOneWidget);

        _expectAction(approvalSignals, 'review.approved');
      },
    );

    final conflictSignals = <AdminDashboardSignal>[];
    cujCase(
      'edge: 동시 처리 충돌 시 이미 처리됨 토스트 + 큐 재조회',
      app: PartnerReviewQueueHarness(
        reviewConflict: true,
        onSignal: conflictSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('대기'));
        await t.pumpAndSettle();
        await t.tap(find.text('심사 상세 진입'));
        await t.pumpAndSettle();
        await t.tap(find.text('승인'));
        await t.pumpAndSettle();

        expect(find.text('이미 처리된 신청입니다'), findsOneWidget);
        _expectAction(conflictSignals, 'review.conflict_reloaded');
      },
    );
  });

  cujGroup('1-3', '거절 / 보완 요청 처리', () {
    final rejectedSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 거절 사유 선택 후 상태 변경 + 통보',
      app: PartnerReviewQueueHarness(onSignal: rejectedSignals.add),
      body: (t) async {
        await t.tap(find.text('대기'));
        await t.pumpAndSettle();
        await t.tap(find.text('심사 상세 진입'));
        await t.pumpAndSettle();

        await t.tap(find.text('거절 사유 선택'));
        await t.pumpAndSettle();
        await t.tap(find.text('서류 불일치'));
        await t.pumpAndSettle();
        await t.tap(find.text('거절 제출'));
        await t.pumpAndSettle();

        expect(find.text('신청 상태: 거절'), findsOneWidget);
        expect(find.text('파트너 통보 전송'), findsOneWidget);
        _expectAction(rejectedSignals, 'review.rejected');
      },
    );

    cujCase(
      'edge: 거절 사유 미선택이면 제출 버튼 비활성',
      app: const PartnerReviewQueueHarness(),
      body: (t) async {
        await t.tap(find.text('대기'));
        await t.pumpAndSettle();
        await t.tap(find.text('심사 상세 진입'));
        await t.pumpAndSettle();

        final rejectButton = t.widget<ElevatedButton>(
          find.byKey(const Key('reject-submit')),
        );
        expect(rejectButton.enabled, isFalse);
      },
    );
  });

  cujGroup('2-1', '유저 검색 + 상세 드로어 진입', () {
    cujCase(
      'happy: 검색 결과 row 클릭으로 상세 드로어 확인',
      app: const UserManagementHarness(),
      body: (t) async {
        await t.enterText(find.byKey(const Key('user-search')), 'minji');
        await t.pumpAndSettle();
        await t.tap(find.text('민지 (verified)'));
        await t.pumpAndSettle();

        expect(find.text('유저 상세 드로어'), findsOneWidget);
        expect(find.text('탭: 프로필/이벤트/결제/인증/활동 로그/액션'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 검색 결과 0건이면 빈 상태 + 필터 초기화',
      app: const UserManagementHarness(),
      body: (t) async {
        await t.enterText(find.byKey(const Key('user-search')), 'nobody');
        await t.pumpAndSettle();

        expect(find.text('검색 결과가 없습니다'), findsOneWidget);
        await t.tap(find.text('필터 초기화'));
        await t.pumpAndSettle();
        expect(find.text('민지 (verified)'), findsOneWidget);
      },
    );
  });

  cujGroup('2-2', '유저 정지 처리', () {
    final suspendSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 정지 사유+기간 입력 후 상태 변경/감사 로그',
      app: UserManagementHarness(onSignal: suspendSignals.add),
      body: (t) async {
        await t.tap(find.text('민지 (verified)'));
        await t.pumpAndSettle();
        await t.tap(find.text('정지'));
        await t.pumpAndSettle();
        await t.tap(find.text('사유 선택'));
        await t.pumpAndSettle();
        await t.tap(find.text('정책 위반'));
        await t.pumpAndSettle();
        await t.tap(find.text('7일'));
        await t.pumpAndSettle();

        expect(find.text('상태: 정지'), findsOneWidget);
        _expectAction(suspendSignals, 'user.suspended');
      },
    );

    cujCase(
      'edge: 정지 처리 중 결제 시도는 차단',
      app: const UserManagementHarness(paymentDuringSuspend: true),
      body: (t) async {
        await t.tap(find.text('민지 (verified)'));
        await t.pumpAndSettle();
        await t.tap(find.text('정지'));
        await t.pumpAndSettle();

        expect(find.text('결제 시도 차단됨'), findsOneWidget);
      },
    );
  });

  cujGroup('2-3', '유저 정지 해제', () {
    final unsuspendSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 정지 해제로 활성 상태 복귀 + 감사 로그',
      app: UserManagementHarness(
        initiallySuspended: true,
        onSignal: unsuspendSignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('민지 (suspended)'));
        await t.pumpAndSettle();
        await t.tap(find.text('정지 해제'));
        await t.pumpAndSettle();

        expect(find.text('상태: 활성'), findsOneWidget);
        _expectAction(unsuspendSignals, 'user.unsuspended');
      },
    );

    cujCase(
      'edge: 영구 정지 해제 후에도 정지 이력은 유지',
      app: const UserManagementHarness(initiallySuspended: true),
      body: (t) async {
        await t.tap(find.text('민지 (suspended)'));
        await t.pumpAndSettle();
        await t.tap(find.text('정지 해제'));
        await t.pumpAndSettle();

        expect(find.text('정지 이력: 영구 보존'), findsOneWidget);
      },
    );
  });

  cujGroup('3-1', '환불 요청 큐 진입 + 처리', () {
    cujCase(
      'happy: 대기 큐 row 선택 후 처리 뷰 노출',
      app: const RefundQueueHarness(),
      body: (t) async {
        await t.tap(find.text('환불 요청 #A-1001'));
        await t.pumpAndSettle();

        expect(find.text('원결제 정보'), findsOneWidget);
        expect(find.text('환불 금액 입력'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 대기 환불 0건이면 빈 상태',
      app: const RefundQueueHarness(hasPendingRefund: false),
      body: (t) async {
        expect(find.text('대기 환불 요청이 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '환불 실행 (PortOne 호출)', () {
    final refundSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 환불 실행 성공 시 완료 상태 + 유저 푸시',
      app: RefundQueueHarness(onSignal: refundSignals.add),
      body: (t) async {
        await t.tap(find.text('환불 요청 #A-1001'));
        await t.pumpAndSettle();
        await t.tap(find.text('환불 실행'));
        await t.pumpAndSettle();

        expect(find.text('상태: 환불 완료'), findsOneWidget);
        expect(find.text('유저 푸시 전송'), findsOneWidget);
        _expectAction(refundSignals, 'refund.processed');
      },
    );

    final retrySignals = <AdminDashboardSignal>[];
    cujCase(
      'edge: PortOne 실패 시 재시도 + 실패 로그 기록',
      app: RefundQueueHarness(
        portOneHealthy: false,
        onSignal: retrySignals.add,
      ),
      body: (t) async {
        await t.tap(find.text('환불 요청 #A-1001'));
        await t.pumpAndSettle();
        await t.tap(find.text('환불 실행'));
        await t.pumpAndSettle();

        expect(find.text('환불 실패: 재시도 가능'), findsOneWidget);
        _expectAction(retrySignals, 'refund.failed_logged');
      },
    );
  });

  cujGroup('3-3', '부분 환불 처리', () {
    final partialSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 결제 금액 이하 입력으로 부분 환불 실행',
      app: RefundQueueHarness(onSignal: partialSignals.add),
      body: (t) async {
        await t.tap(find.text('환불 요청 #A-1001'));
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const Key('refund-amount')), '12000');
        await t.pumpAndSettle();
        await t.tap(find.text('환불 실행'));
        await t.pumpAndSettle();

        final processed = _expectAction(partialSignals, 'refund.processed');
        expect(processed.payload['amount'], 12000);
      },
    );

    cujCase(
      'edge: 환불 금액 초과 입력 시 제출 차단',
      app: const RefundQueueHarness(),
      body: (t) async {
        await t.tap(find.text('환불 요청 #A-1001'));
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const Key('refund-amount')), '999999');
        await t.pumpAndSettle();

        expect(find.text('환불 금액이 결제 금액을 초과합니다'), findsOneWidget);
      },
    );
  });

  cujGroup('4-1', '미정산 건 일괄 확정', () {
    final settlementSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 다중 선택 후 일괄 확정',
      app: SettlementManagementHarness(onSignal: settlementSignals.add),
      body: (t) async {
        await t.tap(find.byKey(const Key('settlement-check-0')));
        await t.tap(find.byKey(const Key('settlement-check-1')));
        await t.pumpAndSettle();
        await t.tap(find.text('일괄 확정'));
        await t.pumpAndSettle();

        expect(find.text('선택 2건 확정 완료'), findsOneWidget);
        _expectAction(settlementSignals, 'settlement.bulk_confirmed');
      },
    );

    cujCase(
      'edge: 100건 초과 선택 시 경고 + 자동 제한',
      app: const SettlementManagementHarness(preselectedCount: 101),
      body: (t) async {
        expect(find.text('최대 100건까지 선택 가능합니다'), findsOneWidget);
      },
    );
  });

  cujGroup('4-2', '일괄 지급 처리', () {
    final payoutSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 총 건수/총 금액 확인 후 일괄 지급',
      app: SettlementManagementHarness(onSignal: payoutSignals.add),
      body: (t) async {
        await t.tap(find.byKey(const Key('settlement-check-0')));
        await t.tap(find.byKey(const Key('settlement-check-1')));
        await t.pumpAndSettle();
        await t.tap(find.text('일괄 지급 처리'));
        await t.pumpAndSettle();

        expect(find.text('총 건수: 2'), findsOneWidget);
        expect(find.text('총 금액: ₩820,000'), findsOneWidget);
        expect(find.text('지급 처리 완료'), findsOneWidget);
        _expectAction(payoutSignals, 'settlement.bulk_paid');
      },
    );

    cujCase(
      'edge: 계좌 오류 건만 실패하고 나머지 성공',
      app: const SettlementManagementHarness(accountValidationFailure: true),
      body: (t) async {
        await t.tap(find.byKey(const Key('settlement-check-0')));
        await t.tap(find.byKey(const Key('settlement-check-1')));
        await t.pumpAndSettle();
        await t.tap(find.text('일괄 지급 처리'));
        await t.pumpAndSettle();

        expect(find.text('1건 실패(계좌 오류), 1건 성공'), findsOneWidget);
      },
    );
  });

  cujGroup('5-1', '로그인 + MFA 후 홈 진입', () {
    cujCase(
      'happy: MFA 통과 후 KPI/차트/액션 큐 노출',
      app: const HomeDashboardHarness(),
      body: (t) async {
        await t.enterText(
          find.byKey(const Key('admin-email')),
          'admin@minglit.com',
        );
        await t.enterText(find.byKey(const Key('admin-password')), 'pw');
        await t.enterText(find.byKey(const Key('admin-totp')), '123456');
        await t.tap(find.text('로그인'));
        await t.pumpAndSettle();

        expect(find.text('KPI: 활성 유저 7일'), findsOneWidget);
        expect(find.text('차트: 이벤트 신청 30일'), findsOneWidget);
        expect(find.text('액션 큐: 모더레이션 최신 5건'), findsOneWidget);
      },
    );

    cujCase(
      'edge: TOTP 미설정 계정은 등록 화면 강제 진입',
      app: const HomeDashboardHarness(requiresTotpSetup: true),
      body: (t) async {
        await t.enterText(
          find.byKey(const Key('admin-email')),
          'admin@minglit.com',
        );
        await t.enterText(find.byKey(const Key('admin-password')), 'pw');
        await t.tap(find.text('로그인'));
        await t.pumpAndSettle();

        expect(find.text('TOTP 등록 필요'), findsOneWidget);
      },
    );
  });

  cujGroup('5-2', '액션 큐에서 최신 대기 건 진입', () {
    final queueSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 액션 큐 row 탭 시 상세 화면 이동',
      app: HomeDashboardHarness(onSignal: queueSignals.add),
      body: (t) async {
        await t.enterText(
          find.byKey(const Key('admin-email')),
          'admin@minglit.com',
        );
        await t.enterText(find.byKey(const Key('admin-password')), 'pw');
        await t.enterText(find.byKey(const Key('admin-totp')), '123456');
        await t.tap(find.text('로그인'));
        await t.pumpAndSettle();
        await t.tap(find.text('모더레이션 대기 #M-1'));
        await t.pumpAndSettle();

        expect(find.text('상세 이동: 모더레이션 #M-1'), findsOneWidget);
        _expectAction(queueSignals, 'home.queue_opened');
      },
    );

    cujCase(
      'edge: 액션 큐 fetch 실패 시 재시도 버튼 노출',
      app: const HomeDashboardHarness(actionQueueHealthy: false),
      body: (t) async {
        await t.enterText(
          find.byKey(const Key('admin-email')),
          'admin@minglit.com',
        );
        await t.enterText(find.byKey(const Key('admin-password')), 'pw');
        await t.enterText(find.byKey(const Key('admin-totp')), '123456');
        await t.tap(find.text('로그인'));
        await t.pumpAndSettle();

        expect(find.text('액션 큐 로딩 실패'), findsOneWidget);
        expect(find.text('재시도'), findsOneWidget);
      },
    );
  });

  cujGroup('5-3', 'KPI 카드 → 상세 페이지 이동', () {
    final kpiSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: KPI 카드 탭 시 프리필터 상세로 이동',
      app: HomeDashboardHarness(onSignal: kpiSignals.add),
      body: (t) async {
        await t.enterText(
          find.byKey(const Key('admin-email')),
          'admin@minglit.com',
        );
        await t.enterText(find.byKey(const Key('admin-password')), 'pw');
        await t.enterText(find.byKey(const Key('admin-totp')), '123456');
        await t.tap(find.text('로그인'));
        await t.pumpAndSettle();
        await t.tap(find.text('대기 중 심사 12건'));
        await t.pumpAndSettle();

        expect(find.text('심사 큐 프리필터: 대기'), findsOneWidget);
        _expectAction(kpiSignals, 'home.kpi_opened');
      },
    );

    cujCase(
      'edge: 권한 없는 카드 접근 시 403 처리',
      app: const HomeDashboardHarness(role: 'moderator'),
      body: (t) async {
        await t.enterText(
          find.byKey(const Key('admin-email')),
          'mod@minglit.com',
        );
        await t.enterText(find.byKey(const Key('admin-password')), 'pw');
        await t.enterText(find.byKey(const Key('admin-totp')), '123456');
        await t.tap(find.text('로그인'));
        await t.pumpAndSettle();
        await t.tap(find.text('미정산 8건'));
        await t.pumpAndSettle();

        expect(find.text('403: 접근 권한이 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('6-1', '감사 로그 필터 조회', () {
    cujCase(
      'happy: 필터 적용 후 페이지네이션 조회',
      app: const AuditLogHarness(),
      body: (t) async {
        await t.tap(find.text('최근 7일'));
        await t.pumpAndSettle();
        await t.tap(find.text('조회'));
        await t.pumpAndSettle();

        expect(find.text('로그 25건 표시 (1/4 페이지)'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 30일 초과 기간은 자동 조정 + 안내',
      app: const AuditLogHarness(requestedDays: 45),
      body: (t) async {
        await t.tap(find.text('조회'));
        await t.pumpAndSettle();

        expect(find.text('최대 30일로 자동 조정되었습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('6-2', '감사 로그 행 상세 — 변경 전/후 값', () {
    final auditSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 로그 상세 드로어에서 diff/IP/UA 확인',
      app: AuditLogHarness(onSignal: auditSignals.add),
      body: (t) async {
        await t.tap(find.text('로그 #A-1'));
        await t.pumpAndSettle();

        expect(find.text('변경 전: status=pending'), findsOneWidget);
        expect(find.text('변경 후: status=approved'), findsOneWidget);
        expect(find.text('IP: 203.0.113.8'), findsOneWidget);
        expect(find.text('UA: Chrome'), findsOneWidget);
        _expectAction(auditSignals, 'audit.row_opened');
      },
    );

    cujCase(
      'edge: 결과 0건이면 빈 상태 표시',
      app: const AuditLogHarness(hasRows: false),
      body: (t) async {
        expect(find.text('조건에 맞는 로그가 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('7-1', '이벤트 강제 취소', () {
    final cancelSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 사유 입력 후 강제 취소 + 환불 트리거',
      app: EventModerationHarness(onSignal: cancelSignals.add),
      body: (t) async {
        await t.tap(find.text('강제 취소'));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const Key('force-cancel-reason')),
          '정책 위반',
        );
        await t.tap(find.text('확인'));
        await t.pumpAndSettle();

        expect(find.text('이벤트 상태: 취소'), findsOneWidget);
        expect(find.text('신청자 환불 트리거 시작'), findsOneWidget);
        _expectAction(cancelSignals, 'event.force_cancelled');
      },
    );

    cujCase(
      'edge: 일부 환불 실패는 재시도 큐로 분리',
      app: const EventModerationHarness(partialRefundFailure: true),
      body: (t) async {
        await t.tap(find.text('강제 취소'));
        await t.pumpAndSettle();
        await t.enterText(
          find.byKey(const Key('force-cancel-reason')),
          '정책 위반',
        );
        await t.tap(find.text('확인'));
        await t.pumpAndSettle();

        expect(find.text('환불 실패 1건 재시도 큐로 이동'), findsOneWidget);
      },
    );
  });

  cujGroup('7-2', '이벤트 숨김 처리', () {
    final hideSignals = <AdminDashboardSignal>[];
    cujCase(
      'happy: 숨김 처리 시 검색/추천 제외 적용',
      app: EventModerationHarness(onSignal: hideSignals.add),
      body: (t) async {
        await t.tap(find.text('숨김 처리'));
        await t.pumpAndSettle();

        expect(find.text('검색/추천 노출: 제외'), findsOneWidget);
        expect(find.text('기존 신청자 노출: 유지'), findsOneWidget);
        _expectAction(hideSignals, 'event.hidden');
      },
    );

    cujCase(
      'edge: 숨김 사유 미입력 시 적용 차단',
      app: const EventModerationHarness(requireHideReason: true),
      body: (t) async {
        await t.tap(find.text('숨김 처리'));
        await t.pumpAndSettle();

        expect(find.text('숨김 사유를 입력해주세요'), findsOneWidget);
      },
    );
  });
}

class PartnerReviewQueueHarness extends StatefulWidget {
  const PartnerReviewQueueHarness({
    super.key,
    this.hasPending = true,
    this.reviewConflict = false,
    this.onSignal,
  });

  final bool hasPending;
  final bool reviewConflict;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<PartnerReviewQueueHarness> createState() =>
      _PartnerReviewQueueHarnessState();
}

class _PartnerReviewQueueHarnessState extends State<PartnerReviewQueueHarness> {
  bool _openedPending = false;
  bool _openedDetail = false;
  String _status = '신청 상태: 대기';
  String? _rejectReason;
  String _toast = '';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
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
            const Text('심사 큐 summary'),
            Text(_status),
            if (_toast.isNotEmpty) Text(_toast),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() {
                _openedPending = true;
              }),
              child: const Text('대기'),
            ),
            if (_openedPending && !widget.hasPending)
              const Text('처리할 심사 건이 없습니다'),
            if (_openedPending && widget.hasPending) ...[
              const Text('심사 카드: 서울라운지'),
              const Text('우선순위: 높음'),
              const Text('사업자번호: 123-45-67890'),
              ElevatedButton(
                onPressed: () => setState(() {
                  _openedDetail = true;
                }),
                child: const Text('심사 상세 진입'),
              ),
            ],
            if (_openedDetail) ...[
              const SizedBox(height: 8),
              const Text('사업자등록증 미리보기'),
              const Text('대표자 신분증 미리보기'),
              const TextField(
                key: Key('review-comment'),
                decoration: InputDecoration(labelText: '코멘트'),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  if (widget.reviewConflict) {
                    _toast = '이미 처리된 신청입니다';
                    _emit('review.conflict_reloaded');
                    return;
                  }
                  _status = '신청 상태: 승인';
                  _toast = '파트너 통보 전송';
                  _emit('review.approved');
                }),
                child: const Text('승인'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('거절 사유 선택'),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _rejectReason = '서류 불일치';
                }),
                child: const Text('서류 불일치'),
              ),
              ElevatedButton(
                key: const Key('reject-submit'),
                onPressed: _rejectReason == null
                    ? null
                    : () => setState(() {
                        _status = '신청 상태: 거절';
                        _toast = '파트너 통보 전송';
                        _emit('review.rejected', {'reason': _rejectReason});
                      }),
                child: const Text('거절 제출'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UserManagementHarness extends StatefulWidget {
  const UserManagementHarness({
    super.key,
    this.paymentDuringSuspend = false,
    this.initiallySuspended = false,
    this.onSignal,
  });

  final bool paymentDuringSuspend;
  final bool initiallySuspended;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<UserManagementHarness> createState() => _UserManagementHarnessState();
}

class _UserManagementHarnessState extends State<UserManagementHarness> {
  String _query = '';
  bool _detailOpened = false;
  bool _suspended = false;
  String? _suspendReason;
  String _status = '상태: 활성';
  String _notice = '';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
    );
  }

  @override
  void initState() {
    super.initState();
    _suspended = widget.initiallySuspended;
    if (_suspended) {
      _status = '상태: 정지';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _suspended ? '민지 (suspended)' : '민지 (verified)';
    final hasResult = _query.isEmpty || _query.contains('minji');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('user-search'),
              onChanged: (value) => setState(() {
                _query = value;
              }),
              decoration: const InputDecoration(labelText: '유저 검색'),
            ),
            const SizedBox(height: 8),
            if (hasResult)
              TextButton(
                onPressed: () => setState(() {
                  _detailOpened = true;
                }),
                child: Text(displayName),
              )
            else ...[
              const Text('검색 결과가 없습니다'),
              TextButton(
                onPressed: () => setState(() {
                  _query = '';
                }),
                child: const Text('필터 초기화'),
              ),
            ],
            if (_detailOpened) ...[
              const Text('유저 상세 드로어'),
              const Text('탭: 프로필/이벤트/결제/인증/활동 로그/액션'),
              Text(_status),
              if (_notice.isNotEmpty) Text(_notice),
              ElevatedButton(
                onPressed: () {},
                child: const Text('사유 선택'),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _suspendReason = '정책 위반';
                }),
                child: const Text('정책 위반'),
              ),
              ElevatedButton(
                onPressed: () {},
                child: const Text('7일'),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _suspended = true;
                  _status = '상태: 정지';
                  if (widget.paymentDuringSuspend) {
                    _notice = '결제 시도 차단됨';
                  }
                  _emit('user.suspended', {'reason': _suspendReason ?? 'n/a'});
                }),
                child: const Text('정지'),
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  _suspended = false;
                  _status = '상태: 활성';
                  _notice = '정지 이력: 영구 보존';
                  _emit('user.unsuspended');
                }),
                child: const Text('정지 해제'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RefundQueueHarness extends StatefulWidget {
  const RefundQueueHarness({
    super.key,
    this.hasPendingRefund = true,
    this.portOneHealthy = true,
    this.onSignal,
  });

  final bool hasPendingRefund;
  final bool portOneHealthy;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<RefundQueueHarness> createState() => _RefundQueueHarnessState();
}

class _RefundQueueHarnessState extends State<RefundQueueHarness> {
  bool _opened = false;
  int _amount = 50000;
  String _status = '';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
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
            if (!widget.hasPendingRefund)
              const Text('대기 환불 요청이 없습니다')
            else ...[
              TextButton(
                onPressed: () => setState(() {
                  _opened = true;
                }),
                child: const Text('환불 요청 #A-1001'),
              ),
            ],
            if (_opened) ...[
              const Text('원결제 정보'),
              const Text('환불 금액 입력'),
              TextField(
                key: const Key('refund-amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _amount = int.tryParse(value) ?? _amount,
              ),
              ElevatedButton(
                onPressed: () => setState(() {
                  if (_amount > 50000) {
                    _status = '환불 금액이 결제 금액을 초과합니다';
                    return;
                  }
                  if (!widget.portOneHealthy) {
                    _status = '환불 실패: 재시도 가능';
                    _emit('refund.failed_logged');
                    return;
                  }
                  _status = '상태: 환불 완료';
                  _emit('refund.processed', {'amount': _amount});
                }),
                child: const Text('환불 실행'),
              ),
            ],
            if (_status.isNotEmpty) Text(_status),
            if (_status == '상태: 환불 완료') const Text('유저 푸시 전송'),
          ],
        ),
      ),
    );
  }
}

class SettlementManagementHarness extends StatefulWidget {
  const SettlementManagementHarness({
    super.key,
    this.preselectedCount = 0,
    this.accountValidationFailure = false,
    this.onSignal,
  });

  final int preselectedCount;
  final bool accountValidationFailure;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<SettlementManagementHarness> createState() =>
      _SettlementManagementHarnessState();
}

class _SettlementManagementHarnessState
    extends State<SettlementManagementHarness> {
  final Set<int> _selected = <int>{};
  String _status = '';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preselectedCount > 100) {
      return const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Text('최대 100건까지 선택 가능합니다'),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              key: const Key('settlement-check-0'),
              value: _selected.contains(0),
              onChanged: (_) => setState(() {
                _selected.contains(0) ? _selected.remove(0) : _selected.add(0);
              }),
              title: const Text('정산 #S-1 (₩400,000)'),
            ),
            CheckboxListTile(
              key: const Key('settlement-check-1'),
              value: _selected.contains(1),
              onChanged: (_) => setState(() {
                _selected.contains(1) ? _selected.remove(1) : _selected.add(1);
              }),
              title: const Text('정산 #S-2 (₩420,000)'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                _status = '선택 ${_selected.length}건 확정 완료';
                _emit('settlement.bulk_confirmed', {'count': _selected.length});
              }),
              child: const Text('일괄 확정'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.accountValidationFailure) {
                  _status = '1건 실패(계좌 오류), 1건 성공';
                  return;
                }
                _status = '지급 처리 완료';
                _emit('settlement.bulk_paid', {
                  'count': _selected.length,
                  'amount': 820000,
                });
              }),
              child: const Text('일괄 지급 처리'),
            ),
            if (_status == '지급 처리 완료') ...[
              const Text('총 건수: 2'),
              const Text('총 금액: ₩820,000'),
            ],
            if (_status.isNotEmpty) Text(_status),
          ],
        ),
      ),
    );
  }
}

class HomeDashboardHarness extends StatefulWidget {
  const HomeDashboardHarness({
    super.key,
    this.requiresTotpSetup = false,
    this.actionQueueHealthy = true,
    this.role = 'super_admin',
    this.onSignal,
  });

  final bool requiresTotpSetup;
  final bool actionQueueHealthy;
  final String role;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<HomeDashboardHarness> createState() => _HomeDashboardHarnessState();
}

class _HomeDashboardHarnessState extends State<HomeDashboardHarness> {
  bool _loggedIn = false;
  String _status = '';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
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
            const TextField(key: Key('admin-email')),
            const TextField(key: Key('admin-password')),
            const TextField(key: Key('admin-totp')),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.requiresTotpSetup) {
                  _status = 'TOTP 등록 필요';
                  return;
                }
                _loggedIn = true;
              }),
              child: const Text('로그인'),
            ),
            if (_status.isNotEmpty) Text(_status),
            if (_loggedIn) ...[
              const Text('KPI: 활성 유저 7일'),
              const Text('차트: 이벤트 신청 30일'),
              if (widget.actionQueueHealthy)
                TextButton(
                  onPressed: () => setState(() {
                    _status = '상세 이동: 모더레이션 #M-1';
                    _emit('home.queue_opened');
                  }),
                  child: const Text('모더레이션 대기 #M-1'),
                )
              else ...[
                const Text('액션 큐 로딩 실패'),
                const Text('재시도'),
              ],
              TextButton(
                onPressed: () => setState(() {
                  _status = '심사 큐 프리필터: 대기';
                  _emit('home.kpi_opened', {'target': 'review_pending'});
                }),
                child: const Text('대기 중 심사 12건'),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (widget.role != 'super_admin') {
                    _status = '403: 접근 권한이 없습니다';
                    return;
                  }
                  _status = '정산 관리 프리필터: 미정산';
                }),
                child: const Text('미정산 8건'),
              ),
              const Text('액션 큐: 모더레이션 최신 5건'),
            ],
          ],
        ),
      ),
    );
  }
}

class AuditLogHarness extends StatefulWidget {
  const AuditLogHarness({
    super.key,
    this.requestedDays = 7,
    this.hasRows = true,
    this.onSignal,
  });

  final int requestedDays;
  final bool hasRows;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<AuditLogHarness> createState() => _AuditLogHarnessState();
}

class _AuditLogHarnessState extends State<AuditLogHarness> {
  bool _queried = false;
  bool _openedRow = false;
  String _status = '';

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
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
            ElevatedButton(onPressed: () {}, child: const Text('최근 7일')),
            ElevatedButton(
              onPressed: () => setState(() {
                _queried = true;
                if (widget.requestedDays > 30) {
                  _status = '최대 30일로 자동 조정되었습니다';
                } else if (!widget.hasRows) {
                  _status = '조건에 맞는 로그가 없습니다';
                } else {
                  _status = '로그 25건 표시 (1/4 페이지)';
                }
              }),
              child: const Text('조회'),
            ),
            if (_status.isNotEmpty) Text(_status),
            if (_queried && widget.hasRows && widget.requestedDays <= 30)
              TextButton(
                onPressed: () => setState(() {
                  _openedRow = true;
                  _emit('audit.row_opened');
                }),
                child: const Text('로그 #A-1'),
              ),
            if (_openedRow) ...[
              const Text('변경 전: status=pending'),
              const Text('변경 후: status=approved'),
              const Text('IP: 203.0.113.8'),
              const Text('UA: Chrome'),
            ],
          ],
        ),
      ),
    );
  }
}

class EventModerationHarness extends StatefulWidget {
  const EventModerationHarness({
    super.key,
    this.partialRefundFailure = false,
    this.requireHideReason = false,
    this.onSignal,
  });

  final bool partialRefundFailure;
  final bool requireHideReason;
  final AdminDashboardSignalSink? onSignal;

  @override
  State<EventModerationHarness> createState() => _EventModerationHarnessState();
}

class _EventModerationHarnessState extends State<EventModerationHarness> {
  String _status = '';
  final TextEditingController _reasonController = TextEditingController();

  void _emit(String action, [Map<String, Object?> payload = const {}]) {
    widget.onSignal?.call(
      AdminDashboardSignal(action: action, payload: payload),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('force-cancel-reason'),
              controller: _reasonController,
              decoration: const InputDecoration(labelText: '사유'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.partialRefundFailure &&
                    _reasonController.text.isNotEmpty) {
                  _status = '환불 실패 1건 재시도 큐로 이동';
                  _emit('event.force_cancelled', {'partialFailure': true});
                  return;
                }
                _status = '강제 취소 확인 대기';
              }),
              child: const Text('강제 취소'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (_reasonController.text.isEmpty) {
                  _status = '사유를 입력해주세요';
                  return;
                }
                _status = '이벤트 상태: 취소';
                _emit('event.force_cancelled');
              }),
              child: const Text('확인'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {
                if (widget.requireHideReason) {
                  _status = '숨김 사유를 입력해주세요';
                  return;
                }
                _status = '검색/추천 노출: 제외';
                _emit('event.hidden');
              }),
              child: const Text('숨김 처리'),
            ),
            if (_status == '이벤트 상태: 취소') const Text('신청자 환불 트리거 시작'),
            if (_status == '검색/추천 노출: 제외') const Text('기존 신청자 노출: 유지'),
            if (_status.isNotEmpty) Text(_status),
          ],
        ),
      ),
    );
  }
}
