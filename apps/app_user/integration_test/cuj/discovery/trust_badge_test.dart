// CUJ tests — discovery / trust-badge
//
// 대응 spec: docs/features/discovery/trust-badge/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../_engine/cuj_test.dart';

enum _TrustLevel { none, verified, certified, elite }

class _TrustSnapshot {
  const _TrustSnapshot({
    required this.identityVerified,
    required this.approvedCredentialCount,
    required this.attendanceRate,
    this.pendingReview = false,
    this.credentialExpired = false,
  });

  final bool identityVerified;
  final int approvedCredentialCount;
  final double attendanceRate;
  final bool pendingReview;
  final bool credentialExpired;
}

_TrustLevel _deriveLevel(_TrustSnapshot s) {
  if (!s.identityVerified) return _TrustLevel.none;
  final hasApprovedCredential =
      s.approvedCredentialCount > 0 && !s.credentialExpired;
  if (!hasApprovedCredential) return _TrustLevel.verified;
  if (s.attendanceRate >= 95.0) return _TrustLevel.elite;
  return _TrustLevel.certified;
}

String _levelLabel(_TrustLevel level) {
  switch (level) {
    case _TrustLevel.none:
      return '미인증';
    case _TrustLevel.verified:
      return 'Verified';
    case _TrustLevel.certified:
      return 'Certified';
    case _TrustLevel.elite:
      return 'Elite';
  }
}

IconData _levelIcon(_TrustLevel level) {
  switch (level) {
    case _TrustLevel.none:
      return Icons.shield_outlined;
    case _TrustLevel.verified:
      return Icons.verified_user_outlined;
    case _TrustLevel.certified:
      return Icons.auto_awesome_outlined;
    case _TrustLevel.elite:
      return Icons.diamond_outlined;
  }
}

class _TrustBadgeButton extends StatelessWidget {
  const _TrustBadgeButton({
    required this.level,
    required this.onTap,
    this.keyName = 'trust-badge',
  });

  final _TrustLevel level;
  final VoidCallback onTap;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key(keyName),
      onPressed: onTap,
      icon: Icon(_levelIcon(level), semanticLabel: _levelLabel(level)),
    );
  }
}

class _TrustSheet extends StatelessWidget {
  const _TrustSheet({
    required this.userName,
    required this.level,
    required this.items,
    required this.attendanceMessage,
    this.showSelfCta = false,
    this.contextCtaLabel,
    this.onContextCta,
  });

  final String userName;
  final _TrustLevel level;
  final List<String> items;
  final String attendanceMessage;
  final bool showSelfCta;
  final String? contextCtaLabel;
  final VoidCallback? onContextCta;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$userName · ${_levelLabel(level)}'),
            const SizedBox(height: 8),
            const Text('3-Layer 진행 상태'),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('아직 인증된 항목이 없어요')
            else
              ...items.map(Text.new),
            const SizedBox(height: 8),
            Text(attendanceMessage),
            if (showSelfCta) ...[
              const SizedBox(height: 8),
              const Text('인증 항목 추가'),
            ],
            if (contextCtaLabel != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onContextCta,
                child: Text(contextCtaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyTrustHarness extends StatefulWidget {
  const _MyTrustHarness({
    required this.initial,
    this.appKilledAfterVerification = false,
  });

  final _TrustSnapshot initial;
  final bool appKilledAfterVerification;

  @override
  State<_MyTrustHarness> createState() => _MyTrustHarnessState();
}

class _MyTrustHarnessState extends State<_MyTrustHarness> {
  late _TrustSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initial;
  }

  void _openSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => _TrustSheet(
          userName: '나',
          level: _deriveLevel(_snapshot),
          items: _snapshot.approvedCredentialCount > 0
              ? const ['[직장] 인증 완료', '[학력] 인증 완료']
              : const [],
          attendanceMessage:
              '최근 출석률 ${_snapshot.attendanceRate.toStringAsFixed(0)}%',
          showSelfCta: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _deriveLevel(_snapshot);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 등급: ${_levelLabel(level)}'),
            if (_snapshot.pendingReview) const Text('심사 중'),
            const SizedBox(height: 8),
            _TrustBadgeButton(level: level, onTap: _openSheet),
            if (!_snapshot.identityVerified)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _snapshot = const _TrustSnapshot(
                      identityVerified: false,
                      approvedCredentialCount: 0,
                      attendanceRate: 0,
                    );
                  });
                },
                child: const Text('본인확인 시작'),
              ),
            if (_snapshot.identityVerified &&
                _snapshot.approvedCredentialCount == 0)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _snapshot = const _TrustSnapshot(
                      identityVerified: true,
                      approvedCredentialCount: 0,
                      attendanceRate: 0,
                      pendingReview: true,
                    );
                  });
                },
                child: const Text('자격인증 추가'),
              ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _snapshot = const _TrustSnapshot(
                    identityVerified: true,
                    approvedCredentialCount: 0,
                    attendanceRate: 0,
                  );
                });
              },
              child: Text(
                widget.appKilledAfterVerification ? '앱 재진입 시뮬레이션' : '본인확인 완료',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Participant {
  const _Participant({
    required this.name,
    required this.level,
    this.blocked = false,
  });

  final String name;
  final _TrustLevel level;
  final bool blocked;
}

class _ParticipantListHarness extends StatelessWidget {
  const _ParticipantListHarness({
    required this.participants,
    this.showContextCta = false,
    this.eventClosed = false,
  });

  final List<_Participant> participants;
  final bool showContextCta;
  final bool eventClosed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: participants.map((p) {
          return ListTile(
            title: Text(p.name),
            trailing: p.blocked
                ? null
                : _TrustBadgeButton(
                    keyName: 'badge-${p.name}',
                    level: p.level,
                    onTap: () {
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => _TrustSheet(
                            userName: p.name,
                            level: p.level,
                            items: const ['[직장] 파트너 인증 · 2026-05-01'],
                            attendanceMessage: '최근 출석률 100%',
                            contextCtaLabel: showContextCta ? '매칭 신청' : null,
                            onContextCta: showContextCta
                                ? () {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          eventClosed
                                              ? '이벤트가 마감되었습니다'
                                              : '매칭 신청으로 이동',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChatHeaderHarness extends StatelessWidget {
  const _ChatHeaderHarness({
    required this.deleted,
  });

  final bool deleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Text(deleted ? '익명' : '상대 유저'),
          if (!deleted)
            _TrustBadgeButton(
              keyName: 'chat-badge',
              level: _TrustLevel.certified,
              onTap: () {
                unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const _TrustSheet(
                      userName: '상대 유저',
                      level: _TrustLevel.certified,
                      items: ['[학력] 인증 완료'],
                      attendanceMessage: '최근 출석률 98%',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LifecycleHarness extends StatefulWidget {
  const _LifecycleHarness({
    required this.realtimeEnabled,
  });

  final bool realtimeEnabled;

  @override
  State<_LifecycleHarness> createState() => _LifecycleHarnessState();
}

class _LifecycleHarnessState extends State<_LifecycleHarness> {
  _TrustSnapshot _snapshot = const _TrustSnapshot(
    identityVerified: true,
    approvedCredentialCount: 0,
    attendanceRate: 90,
  );
  bool _pendingPartnerApproval = false;
  bool _showRenewalGuide = false;

  void _applyPending() {
    if (_pendingPartnerApproval) {
      _snapshot = const _TrustSnapshot(
        identityVerified: true,
        approvedCredentialCount: 1,
        attendanceRate: 90,
      );
      _pendingPartnerApproval = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _deriveLevel(_snapshot);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현재 등급: ${_levelLabel(level)}'),
          if (_showRenewalGuide) const Text('인증 갱신 안내'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (widget.realtimeEnabled) {
                  _snapshot = const _TrustSnapshot(
                    identityVerified: true,
                    approvedCredentialCount: 1,
                    attendanceRate: 90,
                  );
                } else {
                  _pendingPartnerApproval = true;
                }
              });
            },
            child: const Text('파트너 인증 승인 이벤트'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(_applyPending);
            },
            child: const Text('다음 화면 진입'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _snapshot = const _TrustSnapshot(
                  identityVerified: true,
                  approvedCredentialCount: 1,
                  attendanceRate: 95,
                );
              });
            },
            child: const Text('출석률 95 도달'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _snapshot = const _TrustSnapshot(
                  identityVerified: true,
                  approvedCredentialCount: 1,
                  attendanceRate: 94.5,
                );
              });
            },
            child: const Text('출석률 94.5'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _snapshot = const _TrustSnapshot(
                  identityVerified: true,
                  approvedCredentialCount: 1,
                  attendanceRate: 90,
                  credentialExpired: true,
                );
                _showRenewalGuide = true;
              });
            },
            child: const Text('인증 만료'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _snapshot = const _TrustSnapshot(
                  identityVerified: true,
                  approvedCredentialCount: 0,
                  attendanceRate: 90,
                  pendingReview: true,
                );
              });
            },
            child: const Text('갱신 신청'),
          ),
        ],
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '미인증 유저가 마이페이지에서 자기 등급 확인', () {
    cujCase(
      'happy: 미인증 상태 + 본인확인 시작 CTA 노출',
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _MyTrustHarness(
        initial: _TrustSnapshot(
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
      app: const _ParticipantListHarness(
        participants: [
          _Participant(name: 'none', level: _TrustLevel.none),
          _Participant(name: 'verified', level: _TrustLevel.verified),
          _Participant(name: 'certified', level: _TrustLevel.certified),
          _Participant(name: 'elite', level: _TrustLevel.elite),
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
      app: _ParticipantListHarness(
        participants: List.generate(
          16,
          (i) => _Participant(
            name: 'user-$i',
            level: i.isEven ? _TrustLevel.verified : _TrustLevel.certified,
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
      app: const _ParticipantListHarness(
        participants: [
          _Participant(name: '민지', level: _TrustLevel.certified),
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
      app: const _ParticipantListHarness(
        participants: [
          _Participant(
            name: '차단유저',
            level: _TrustLevel.certified,
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
      app: const _ParticipantListHarness(
        participants: [
          _Participant(name: '지원', level: _TrustLevel.certified),
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
      app: const _ParticipantListHarness(
        participants: [
          _Participant(name: '지원', level: _TrustLevel.certified),
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
      app: const _ChatHeaderHarness(deleted: false),
      body: (t) async {
        expect(find.byKey(const Key('chat-badge')), findsOneWidget);
        await t.tap(find.byKey(const Key('chat-badge')));
        await t.pumpAndSettle();
        expect(find.text('상대 유저 · Certified'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 탈퇴 상대는 배지 미노출 + 익명 표시',
      app: const _ChatHeaderHarness(deleted: true),
      body: (t) async {
        expect(find.text('익명'), findsOneWidget);
        expect(find.byKey(const Key('chat-badge')), findsNothing);
      },
    );
  });

  cujGroup('3-1', '파트너 인증 승인 시 등급 자동 상승', () {
    cujCase(
      'happy: 승인 이벤트 반영 시 Verified → Certified',
      app: const _LifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        expect(find.text('현재 등급: Verified'), findsOneWidget);
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Certified'), findsOneWidget);
      },
    );

    cujCase(
      'edge: realtime 비활성 시 다음 화면 진입에서 반영',
      app: const _LifecycleHarness(realtimeEnabled: false),
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
      app: const _LifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        await t.tap(find.text('출석률 95 도달'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Elite'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 94.5% 경계값은 Elite 미부여(floor 가드)',
      app: const _LifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('파트너 인증 승인 이벤트'));
        await t.pumpAndSettle();
        await t.tap(find.text('출석률 94.5'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Certified'), findsOneWidget);
      },
    );
  });

  cujGroup('3-3', '자격인증 만료 시 등급 자동 강등', () {
    cujCase(
      'happy: 만료 시 Certified → Verified + 갱신 안내',
      app: const _LifecycleHarness(realtimeEnabled: true),
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
      app: const _LifecycleHarness(realtimeEnabled: true),
      body: (t) async {
        await t.tap(find.text('인증 만료'));
        await t.pumpAndSettle();
        await t.tap(find.text('갱신 신청'));
        await t.pumpAndSettle();
        expect(find.text('현재 등급: Verified'), findsOneWidget);
      },
    );
  });
}
