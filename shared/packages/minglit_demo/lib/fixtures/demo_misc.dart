/// Misc fixtures: notifications, verifications, matchings, policies.
///
/// Owned by **P1-5 agent**.
///
/// Exported:
///   - `List<Map<String, dynamic>> demoNotifications` — 7 entries, mix of
///     read/unread, varied type strings (matching, event, system).
///   - `List<VerificationSubmission> demoVerifications` — 2 submissions for
///     demoUser: one approved (career), one pending (asset).
///   - `List<MatchPair> demoMatchings` — 2 successful match outcomes.
///   - `Map<String, dynamic>? demoRefundPolicy` — refund policy stub.
///
/// Constraints:
///   - All timestamps relative to `DemoWorld.now`.
///   - `demoTags` lives in `demo_parties.dart` (P1-2) — not re-exported here.
library;

import 'package:minglit_kit/minglit_data.dart';

import 'demo_world.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

DateTime _t(Duration d) => DemoWorld.offset(d);

// ── IDs (misc domain) ──────────────────────────────────────────────────────

const _notif1Id = '00000000-0000-4000-8000-A00000000001';
const _notif2Id = '00000000-0000-4000-8000-A00000000002';
const _notif3Id = '00000000-0000-4000-8000-A00000000003';
const _notif4Id = '00000000-0000-4000-8000-A00000000004';
const _notif5Id = '00000000-0000-4000-8000-A00000000005';
const _notif6Id = '00000000-0000-4000-8000-A00000000006';
const _notif7Id = '00000000-0000-4000-8000-A00000000007';

const _verif1Id = '00000000-0000-4000-8000-B00000000001'; // career verification def
const _verif2Id = '00000000-0000-4000-8000-B00000000002'; // asset verification def

const _vsub1Id = '00000000-0000-4000-8000-C00000000001'; // approved career submission
const _vsub2Id = '00000000-0000-4000-8000-C00000000002'; // pending asset submission

const _match1Id = '00000000-0000-4000-8000-D00000000001';
const _match2Id = '00000000-0000-4000-8000-D00000000002';

// ── Notifications ──────────────────────────────────────────────────────────

/// 7 notifications for demoUser — mix of unread/read, varied type.
///
/// [NotificationRepository.getNotifications] returns
/// `List<Map<String, dynamic>>` (raw DB rows), so we use the same shape here.
final List<Map<String, dynamic>> demoNotifications = [
  // 1. Unread — matching result (event8, 3 days ago)
  {
    'id': _notif1Id,
    'user_id': DemoWorld.userId,
    'type': 'match_result',
    'title': '매칭 결과가 도착했어요!',
    'body': '이태원 보드게임 나잇에서 새로운 매칭이 성사됐습니다.',
    'data': {'event_id': '00000000-0000-4000-8000-300000000008'},
    'is_read': false,
    'created_at': _t(const Duration(days: -3, hours: -1)).toIso8601String(),
  },
  // 2. Unread — application approved (event2)
  {
    'id': _notif2Id,
    'user_id': DemoWorld.userId,
    'type': 'application_approved',
    'title': '신청이 승인됐습니다.',
    'body': '강남 싱글즈 칵테일 파티 참가 신청이 승인됐어요. 티켓을 확인하세요!',
    'data': {'event_id': DemoWorld.selfEvent2Id},
    'is_read': false,
    'created_at': _t(const Duration(days: -5)).toIso8601String(),
  },
  // 3. Unread — event reminder (event2, starts in 2 days)
  {
    'id': _notif3Id,
    'user_id': DemoWorld.userId,
    'type': 'event_reminder',
    'title': '이벤트 D-2 리마인더',
    'body': '강남 싱글즈 칵테일 파티가 이틀 후에 시작됩니다. 잊지 마세요!',
    'data': {'event_id': DemoWorld.selfEvent2Id},
    'is_read': false,
    'created_at': _t(const Duration(hours: -6)).toIso8601String(),
  },
  // 4. Read — verification approved (career)
  {
    'id': _notif4Id,
    'user_id': DemoWorld.userId,
    'type': 'verification_approved',
    'title': '직장 인증이 완료됐습니다.',
    'body': '제출하신 직장 인증 서류가 승인됐어요. 인증 뱃지가 부여됐습니다.',
    'data': {'verification_id': _verif1Id},
    'is_read': true,
    'created_at': _t(const Duration(days: -8)).toIso8601String(),
  },
  // 5. Read — application rejected (event9)
  {
    'id': _notif5Id,
    'user_id': DemoWorld.userId,
    'type': 'application_rejected',
    'title': '신청이 반려됐습니다.',
    'body': '성수 아트 나잇 참가 신청이 반려됐어요. 사유를 확인하세요.',
    'data': {'event_id': '00000000-0000-4000-8000-300000000009'},
    'is_read': true,
    'created_at': _t(const Duration(days: -23)).toIso8601String(),
  },
  // 6. Read — system notice (service update)
  {
    'id': _notif6Id,
    'user_id': DemoWorld.userId,
    'type': 'system',
    'title': '밍글릿 서비스 업데이트 안내',
    'body': '새로운 기능이 추가됐습니다. 자세한 내용을 확인해보세요.',
    'data': <String, dynamic>{},
    'is_read': true,
    'created_at': _t(const Duration(days: -15)).toIso8601String(),
  },
  // 7. Read — event now (event4 is ongoing right now)
  {
    'id': _notif7Id,
    'user_id': DemoWorld.userId,
    'type': 'event_started',
    'title': '지금 이벤트가 진행 중입니다!',
    'body': '홍대 영화 토크 클럽이 시작됐어요. 입장 QR 코드를 준비하세요.',
    'data': {'event_id': DemoWorld.partner2EventId},
    'is_read': true,
    'created_at': _t(const Duration(hours: -1)).toIso8601String(),
  },
];

// ── Verification Submissions ────────────────────────────────────────────────

/// 2 verification submissions for demoUser.
///
/// - [_vsub1Id]: career verification, **approved** (reviewed 6 days ago).
/// - [_vsub2Id]: asset verification, **pending** (submitted 2 days ago).
final List<VerificationSubmission> demoVerifications = [
  // Submission 1: career — approved
  VerificationSubmission(
    id: _vsub1Id,
    partnerId: DemoWorld.selfPartnerId,
    userId: DemoWorld.userId,
    verificationId: _verif1Id,
    status: VerificationStatus.approved,
    snapshotData: [
      {'key': 'company_name', 'label': '회사명', 'value': '밍글릿 주식회사'},
      {'key': 'department', 'label': '부서', 'value': '제품팀'},
      {'key': 'job_title', 'label': '직함', 'value': '프로덕트 매니저'},
    ],
    createdAt: _t(const Duration(days: -10)),
    updatedAt: _t(const Duration(days: -6)),
    reviewedAt: _t(const Duration(days: -6)),
    reviewedBy: DemoWorld.selfPartnerId,
    reviewStartedAt: _t(const Duration(days: -7)),
  ),

  // Submission 2: asset — pending review
  VerificationSubmission(
    id: _vsub2Id,
    partnerId: DemoWorld.selfPartnerId,
    userId: DemoWorld.userId,
    verificationId: _verif2Id,
    status: VerificationStatus.pending,
    snapshotData: [
      {'key': 'asset_type', 'label': '자산 종류', 'value': '부동산'},
      {'key': 'estimated_value', 'label': '추정 가치', 'value': '3억원 이상'},
    ],
    createdAt: _t(const Duration(days: -2)),
    updatedAt: _t(const Duration(days: -2)),
  ),
];

// ── Match Pairs ────────────────────────────────────────────────────────────

/// 2 successful matches from past events.
///
/// Both refer to event8 (이태원 보드게임 나잇, completed 3 days ago).
final List<MatchPair> demoMatchings = [
  // Match 1: demoUser ↔ fictional matched user A
  MatchPair(
    matchId: _match1Id,
    eventId: '00000000-0000-4000-8000-300000000008',
    partnerId: '00000000-0000-4000-8000-000000000002', // other user
    matchedAt: _t(const Duration(days: -3, hours: -2)),
    partnerName: '서지우',
    partnerProfileImage: 'https://picsum.photos/seed/match1/200/200',
    partnerContact: '+82-10-0000-0002',
  ),
  // Match 2: demoUser ↔ fictional matched user B
  MatchPair(
    matchId: _match2Id,
    eventId: '00000000-0000-4000-8000-300000000008',
    partnerId: '00000000-0000-4000-8000-000000000003', // other user
    matchedAt: _t(const Duration(days: -3, hours: -2, minutes: -30)),
    partnerName: '김나연',
    partnerProfileImage: 'https://picsum.photos/seed/match2/200/200',
    partnerContact: '+82-10-0000-0003',
  ),
];

// ── Policy ──────────────────────────────────────────────────────────────────

/// Stub refund policy returned by [PolicyRepository.getRefundPolicy].
///
/// PolicyRepository uses `Map<String, dynamic>?` directly (no domain model).
final Map<String, dynamic> demoRefundPolicy = {
  'key': 'refund',
  'title': '환불 정책',
  'content':
      '이벤트 시작 48시간 전까지 전액 환불 가능합니다. '
      '그 이후에는 환불이 불가하오니 참고해주세요.',
  'updated_at': _t(const Duration(days: -30)).toIso8601String(),
  'version': '1.0.0',
};
