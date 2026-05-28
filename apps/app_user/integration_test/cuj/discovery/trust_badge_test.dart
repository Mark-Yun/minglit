// CUJ tests — discovery / trust-badge
//
// 대응 spec: docs/features/discovery/trust-badge/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_user/src/features/discovery/trust_badge/ui/trust_badge_contract_harness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '미인증 유저가 마이페이지에서 자기 등급 확인', () {
    cujCase(
      'happy: 미인증 상태 + 본인확인 시작 CTA 노출',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: false,
          approvedCredentialCount: 0,
          attendanceRate: 0,
        ),
      ),
      body: (t) async {
        expect(find.text('현재 등급: 미인증'), findsOneWidget);
        expect(find.text('본인확인 시작'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 인증 취소 후에도 상태 유지 + CTA 재활성',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: false,
          approvedCredentialCount: 0,
          attendanceRate: 0,
        ),
      ),
      body: (t) async {
        await t.tap(find.text('본인확인 시작'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: 미인증'), findsOneWidget);
        expect(find.text('본인확인 시작'), findsOneWidget);
      },
    );
  });

  cujGroup('1-2', '본인확인 완료 후 등급 Verified 자동 상승', () {
    cujCase(
      'happy: 본인확인 완료 시 Verified 로 전환',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: false,
          approvedCredentialCount: 0,
          attendanceRate: 0,
        ),
      ),
      body: (t) async {
        await t.tap(find.text('본인확인 완료'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsOneWidget);
        expect(find.text('자격인증 추가'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 본인확인 후 앱 재진입 시 Verified 유지',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: true,
          approvedCredentialCount: 0,
          attendanceRate: 0,
        ),
        appKilledAfterVerification: true,
      ),
      body: (t) async {
        await t.tap(find.text('앱 재진입 시뮬레이션'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsOneWidget);
      },
    );
  });

  cujGroup('1-3', '자격인증 신청 → 승인 대기 안내', () {
    cujCase(
      'happy: 자격인증 추가 탭 후 심사 중 상태 표시',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: true,
          approvedCredentialCount: 0,
          attendanceRate: 0,
        ),
      ),
      body: (t) async {
        await t.tap(find.text('자격인증 추가'));
        await t.pumpAndSettle();
        expect(find.text('심사 중'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 장기 미승인 상태에서도 심사 중 표시 유지',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: true,
          approvedCredentialCount: 0,
          attendanceRate: 0,
          pendingReview: true,
        ),
      ),
      body: (t) async {
        expect(find.text('심사 중'), findsOneWidget);
      },
    );
  });

  cujGroup('1-4', '본인 배지 탭 → 인증 항목 + 활동 지표 확인', () {
    cujCase(
      'happy: 배지 탭 시 TrustSheet 열림',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: true,
          approvedCredentialCount: 2,
          attendanceRate: 96,
        ),
      ),
      body: (t) async {
        await t.tap(find.byKey(const Key('trust-badge')));
        await t.pumpAndSettle();
        expect(find.text('나 · Elite'), findsOneWidget);
        expect(find.text('최근 출석률 96%'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 인증 항목 없음 시 빈 상태 + 인증 CTA 노출',
      app: const MyTrustHarness(
        initial: TrustSnapshot(
          identityVerified: true,
          approvedCredentialCount: 0,
          attendanceRate: 70,
        ),
      ),
      body: (t) async {
        await t.tap(find.byKey(const Key('trust-badge')));
        await t.pumpAndSettle();
        expect(find.text('아직 인증된 항목이 없어요'), findsOneWidget);
        expect(find.text('인증 항목 추가'), findsOneWidget);
      },
    );
  });

  cujGroup('2-1', '이벤트 참가자 목록에서 타인 배지 확인', () {
    cujCase(
      'happy: 4종 배지가 각각 노출됨',
      app: const ParticipantListHarness(
        participants: [
          Participant(name: 'none', level: TrustLevel.none),
          Participant(name: 'verified', level: TrustLevel.verified),
          Participant(name: 'certified', level: TrustLevel.certified),
          Participant(name: 'elite', level: TrustLevel.elite),
        ],
      ),
      body: (t) async {
        expect(find.bySemanticsLabel('미인증'), findsOneWidget);
        expect(find.bySemanticsLabel('Verified'), findsOneWidget);
        expect(find.bySemanticsLabel('Certified'), findsOneWidget);
        expect(find.bySemanticsLabel('Elite'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 16명 참가자도 배지 렌더가 유지됨',
      app: ParticipantListHarness(
        participants: List.generate(
          16,
          (i) => Participant(
            name: 'user-$i',
            level: i.isEven ? TrustLevel.verified : TrustLevel.certified,
          ),
        ),
      ),
      body: (t) async {
        expect(find.byIcon(Icons.verified_user_outlined), findsWidgets);
        expect(find.byIcon(Icons.auto_awesome_outlined), findsWidgets);
      },
    );
  });

  cujGroup('2-2', '타인 배지 탭 → 신뢰 시트로 근거 확인', () {
    cujCase(
      'happy: 배지 탭 시 인증 내역/출석률 문구 노출',
      app: const ParticipantListHarness(
        participants: [
          Participant(name: '민지', level: TrustLevel.certified),
        ],
      ),
      body: (t) async {
        await t.tap(find.byKey(const Key('badge-민지')));
        await t.pumpAndSettle();
        expect(find.text('민지 · Certified'), findsOneWidget);
        expect(find.text('[직장] 파트너 인증 · 2026-05-01'), findsOneWidget);
        expect(find.text('최근 출석률 100%'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 차단된 유저는 배지/시트 미노출',
      app: const ParticipantListHarness(
        participants: [
          Participant(
            name: '차단유저',
            level: TrustLevel.certified,
            blocked: true,
          ),
        ],
      ),
      body: (t) async {
        expect(find.byKey(const Key('badge-차단유저')), findsNothing);
      },
    );
  });

  cujGroup('2-3', '시트 열람 후 매칭 신청 진입', () {
    cujCase(
      'happy: 매칭 신청 CTA 탭 시 플로우 진입 메시지',
      app: const ParticipantListHarness(
        participants: [
          Participant(name: '지원', level: TrustLevel.certified),
        ],
        showContextCta: true,
      ),
      body: (t) async {
        await t.tap(find.byKey(const Key('badge-지원')));
        await t.pumpAndSettle();
        await t.tap(find.text('매칭 신청'));
        await t.pumpAndSettle();
        expect(find.text('매칭 신청으로 이동'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 이벤트 마감 시 마감 안내 표시',
      app: const ParticipantListHarness(
        participants: [
          Participant(name: '지원', level: TrustLevel.certified),
        ],
        showContextCta: true,
        eventClosed: true,
      ),
      body: (t) async {
        await t.tap(find.byKey(const Key('badge-지원')));
        await t.pumpAndSettle();
        await t.tap(find.text('매칭 신청'));
        await t.pumpAndSettle();
        expect(find.text('이벤트가 마감되었습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('2-4', '채팅 / DM 상대 이름 옆 배지 노출', () {
    cujCase(
      'happy: 채팅 헤더 배지 탭 시 동일 TrustSheet 노출',
      app: const ChatHeaderHarness(deleted: false),
      body: (t) async {
        expect(find.byKey(const Key('chat-badge')), findsOneWidget);
        await t.tap(find.byKey(const Key('chat-badge')));
        await t.pumpAndSettle();
        expect(find.text('상대 유저 · Certified'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 탈퇴 상대는 배지 미노출 + 익명 표시',
      app: const ChatHeaderHarness(deleted: true),
      body: (t) async {
        expect(find.text('익명'), findsOneWidget);
        expect(find.byKey(const Key('chat-badge')), findsNothing);
      },
    );
  });

  cujGroup('3-1', '파트너 인증 승인 시 등급 자동 상승', () {
    cujCase(
      'happy: 승인 이벤트 반영 시 Verified → Certified',
      app: const TrustLifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        expect(find.text('현재 등급: Verified'), findsOneWidget);
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Certified'), findsOneWidget);
      },
    );

    cujCase(
      'edge: realtime 비활성 시 다음 화면 진입에서 반영',
      app: const TrustLifecycleHarness(realtimeEnabled: false),
      body: (t) async {
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsOneWidget);

        await t.tap(find.text('다음 화면 진입'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Certified'), findsOneWidget);
      },
    );
  });

  cujGroup('3-2', '출석률 95% 도달 시 Elite 자동 부여', () {
    cujCase(
      'happy: 95% 도달 시 Elite',
      app: const TrustLifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        await t.tap(find.text('출석률 95 도달'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Elite'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 94.5% 경계값은 정책 미확정 범위(Certified 또는 Elite)',
      app: const TrustLifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        await t.tap(find.text('출석률 94.5'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == '현재 등급: Certified' ||
                    widget.data == '현재 등급: Elite'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  cujGroup('3-3', '자격인증 만료 시 등급 자동 강등', () {
    cujCase(
      'happy: 만료 시 Certified → Verified + 갱신 안내',
      app: const TrustLifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        await t.tap(find.text('인증 만료'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsOneWidget);
        expect(find.text('인증 갱신 안내'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 만료 직후 갱신 신청 시 심사 중 상태',
      app: const TrustLifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('인증 만료'));
        await t.pumpAndSettle();
        await t.tap(find.text('갱신 신청'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsOneWidget);
        expect(find.text('심사 중'), findsOneWidget);
      },
    );
  });
}
