/// Partner-domain fixtures: `Partner`, `PartnerApplication`, and partner
/// member role data (as raw maps — same shape returned by
/// `getPartnerMembers` RPC).
///
/// Owned by **P1-4 agent**. See task #14.
library;

import 'package:minglit_kit/minglit_kit.dart';

import 'demo_world.dart';

// ── Partners ─────────────────────────────────────────────────────────────────

/// The partner store that demoUser owns — the primary context in partner_app.
final Partner demoPartnerSelf = Partner(
  id: DemoWorld.selfPartnerId,
  name: '민글릿 라운지 강남',
  introduction: '강남 한복판에서 즐기는 프리미엄 소셜 파티. 매달 새로운 테마로 진행됩니다.',
  address: '서울특별시 강남구 테헤란로 123, 4층',
  contactPhone: '02-0000-1001',
  contactEmail: 'lounge@minglit.app',
  representativeName: '김데모',
  bizName: '(주)민글릿라운지',
  bizNumber: '123-45-67890',
  profileImageUrl:
      'https://placehold.co/400x400/7C3AED/ffffff?text=ML+Lounge',
  isActive: true,
);

/// Partner 2 — rooftop venue in Mapo.
final Partner demoPartner2 = Partner(
  id: DemoWorld.partner2Id,
  name: '루프탑 소셜 마포',
  introduction: '마포 한강변 루프탑에서 즐기는 소셜 파티.',
  address: '서울특별시 마포구 와우산로 45, 옥상',
  contactPhone: '02-0000-1002',
  contactEmail: 'rooftop@example.com',
  representativeName: '이루프',
  bizName: '루프탑소셜(주)',
  bizNumber: '234-56-78901',
  profileImageUrl:
      'https://placehold.co/400x400/0EA5E9/ffffff?text=Rooftop',
  isActive: true,
);

/// Partner 3 — jazz bar in Itaewon.
final Partner demoPartner3 = Partner(
  id: DemoWorld.partner3Id,
  name: '이태원 재즈 클럽',
  introduction: '이태원에서 라이브 재즈와 함께하는 소셜 이벤트.',
  address: '서울특별시 용산구 이태원로 78',
  contactPhone: '02-0000-1003',
  contactEmail: 'jazz@example.com',
  representativeName: '박재즈',
  bizName: '재즈클럽(주)',
  bizNumber: '345-67-89012',
  profileImageUrl:
      'https://placehold.co/400x400/F59E0B/000000?text=Jazz',
  isActive: true,
);

/// Partner 4 — art gallery venue in Seongsu.
final Partner demoPartner4 = Partner(
  id: DemoWorld.partner4Id,
  name: '성수 아트 갤러리',
  introduction: '성수동 힙한 갤러리 공간에서 펼쳐지는 아트 소셜.',
  address: '서울특별시 성동구 성수이로 99',
  contactPhone: '02-0000-1004',
  contactEmail: 'art@example.com',
  representativeName: '최아트',
  bizName: '아트갤러리(주)',
  bizNumber: '456-78-90123',
  profileImageUrl:
      'https://placehold.co/400x400/10B981/ffffff?text=Art',
  isActive: true,
);

/// Partner 5 — wine bar in Apgujeong.
final Partner demoPartner5 = Partner(
  id: DemoWorld.partner5Id,
  name: '압구정 와인바',
  introduction: '압구정 프리미엄 와인바에서 즐기는 와인 소셜 클래스.',
  address: '서울특별시 강남구 압구정로 210',
  contactPhone: '02-0000-1005',
  contactEmail: 'wine@example.com',
  representativeName: '정와인',
  bizName: '와인바(주)',
  bizNumber: '567-89-01234',
  profileImageUrl:
      'https://placehold.co/400x400/EF4444/ffffff?text=Wine',
  isActive: true,
);

/// Full partner list — used by app_user browse and app_partner queries.
/// demoPartnerSelf is always first.
final List<Partner> demoPartners = [
  demoPartnerSelf,
  demoPartner2,
  demoPartner3,
  demoPartner4,
  demoPartner5,
];

// ── Partner Applications ──────────────────────────────────────────────────────

/// demoUser's partner application history.
/// - First entry: approved (current partner, 6 months ago).
/// - Second entry: a second venue application still pending review.
final List<PartnerApplication> demoPartnerApplications = [
  PartnerApplication(
    id: '00000000-0000-4000-8000-500000000001',
    userId: DemoWorld.userId,
    status: 'approved',
    contactPhone: '02-0000-1001',
    contactEmail: 'lounge@minglit.app',
    brandName: '민글릿 라운지 강남',
    introduction: '강남 한복판에서 즐기는 프리미엄 소셜 파티.',
    address: '서울특별시 강남구 테헤란로 123, 4층',
    bizType: 'corporation',
    bizName: '(주)민글릿라운지',
    bizNumber: '123-45-67890',
    representativeName: '김데모',
    bankName: '농협은행',
    accountNumber: '301-0000-0001-01',
    accountHolder: '김데모',
    taxEmail: 'tax@minglit.app',
    currentStep: 4,
    adminComment: '입점 승인되었습니다. 환영합니다!',
    createdAt: DemoWorld.offset(const Duration(days: -180)).toIso8601String(),
    updatedAt: DemoWorld.offset(const Duration(days: -175)).toIso8601String(),
  ),
  PartnerApplication(
    id: '00000000-0000-4000-8000-500000000002',
    userId: DemoWorld.userId,
    status: 'pending',
    contactPhone: '02-0000-1099',
    contactEmail: 'second@minglit.app',
    brandName: '민글릿 라운지 홍대',
    introduction: '홍대 인근 신규 소셜 공간 오픈 예정.',
    address: '서울특별시 마포구 홍익로 55',
    bizType: 'corporation',
    bizName: '(주)민글릿라운지',
    bizNumber: '123-45-67890',
    representativeName: '김데모',
    currentStep: 3,
    createdAt: DemoWorld.offset(const Duration(days: -14)).toIso8601String(),
    updatedAt: DemoWorld.offset(const Duration(days: -14)).toIso8601String(),
  ),
];

// ── Partner Members ───────────────────────────────────────────────────────────

/// Partner member fixtures as raw maps — same shape returned by
/// `getPartnerMembers` RPC (flat + nested `user` key).
///
/// Role values: 'owner' | 'manager' | 'staff'
/// (matches partner_member_permissions.role column convention).
final List<Map<String, dynamic>> demoPartnerMembers = [
  {
    'user_id': DemoWorld.userId,
    'partner_id': DemoWorld.selfPartnerId,
    'role': 'owner',
    'permissions': ['ALL'],
    'joined_at':
        DemoWorld.offset(const Duration(days: -180)).toIso8601String(),
    'user_name': '김데모',
    'user_profile_image': null,
    'user': {
      'id': DemoWorld.userId,
      'name': '김데모',
      'email': DemoWorld.userEmail,
      'profile_image': null,
    },
  },
  {
    'user_id': '00000000-0000-4000-8000-000000000002',
    'partner_id': DemoWorld.selfPartnerId,
    'role': 'manager',
    'permissions': ['EVENT_MANAGE', 'CHECKIN'],
    'joined_at':
        DemoWorld.offset(const Duration(days: -90)).toIso8601String(),
    'user_name': '이매니저',
    'user_profile_image': null,
    'user': {
      'id': '00000000-0000-4000-8000-000000000002',
      'name': '이매니저',
      'email': 'manager@example.com',
      'profile_image': null,
    },
  },
];
