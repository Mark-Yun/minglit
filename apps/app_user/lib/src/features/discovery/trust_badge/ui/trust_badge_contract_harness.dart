import 'dart:async';

import 'package:flutter/material.dart';

enum TrustLevel { none, verified, certified, elite }

class TrustSnapshot {
  const TrustSnapshot({
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

TrustLevel deriveTrustLevel(TrustSnapshot snapshot) {
  if (!snapshot.identityVerified) return TrustLevel.none;
  final hasApprovedCredential =
      snapshot.approvedCredentialCount > 0 && !snapshot.credentialExpired;
  if (!hasApprovedCredential) return TrustLevel.verified;
  if (snapshot.attendanceRate >= 95.0) return TrustLevel.elite;
  return TrustLevel.certified;
}

String trustLevelLabel(TrustLevel level) {
  switch (level) {
    case TrustLevel.none:
      return '미인증';
    case TrustLevel.verified:
      return 'Verified';
    case TrustLevel.certified:
      return 'Certified';
    case TrustLevel.elite:
      return 'Elite';
  }
}

IconData trustLevelIcon(TrustLevel level) {
  switch (level) {
    case TrustLevel.none:
      return Icons.shield_outlined;
    case TrustLevel.verified:
      return Icons.verified_user_outlined;
    case TrustLevel.certified:
      return Icons.auto_awesome_outlined;
    case TrustLevel.elite:
      return Icons.diamond_outlined;
  }
}

class TrustBadgeButton extends StatelessWidget {
  const TrustBadgeButton({
    required this.level,
    required this.onTap,
    this.keyName = 'trust-badge',
    super.key,
  });

  final TrustLevel level;
  final VoidCallback onTap;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key(keyName),
      onPressed: onTap,
      icon: Icon(trustLevelIcon(level), semanticLabel: trustLevelLabel(level)),
    );
  }
}

class TrustSheet extends StatelessWidget {
  const TrustSheet({
    required this.userName,
    required this.level,
    required this.items,
    required this.attendanceMessage,
    this.showSelfCta = false,
    this.contextCtaLabel,
    this.onContextCta,
    super.key,
  });

  final String userName;
  final TrustLevel level;
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
            Text('$userName · ${trustLevelLabel(level)}'),
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

class MyTrustHarness extends StatefulWidget {
  const MyTrustHarness({
    required this.initial,
    this.appKilledAfterVerification = false,
    super.key,
  });

  final TrustSnapshot initial;
  final bool appKilledAfterVerification;

  @override
  State<MyTrustHarness> createState() => _MyTrustHarnessState();
}

class _MyTrustHarnessState extends State<MyTrustHarness> {
  late TrustSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initial;
  }

  void _openSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => TrustSheet(
          userName: '나',
          level: deriveTrustLevel(_snapshot),
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
    final level = deriveTrustLevel(_snapshot);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 등급: ${trustLevelLabel(level)}'),
            if (_snapshot.pendingReview) const Text('심사 중'),
            const SizedBox(height: 8),
            TrustBadgeButton(level: level, onTap: _openSheet),
            if (!_snapshot.identityVerified)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _snapshot = const TrustSnapshot(
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
                    _snapshot = const TrustSnapshot(
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
                  _snapshot = const TrustSnapshot(
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

class Participant {
  const Participant({
    required this.name,
    required this.level,
    this.blocked = false,
  });

  final String name;
  final TrustLevel level;
  final bool blocked;
}

class ParticipantListHarness extends StatelessWidget {
  const ParticipantListHarness({
    required this.participants,
    this.showContextCta = false,
    this.eventClosed = false,
    super.key,
  });

  final List<Participant> participants;
  final bool showContextCta;
  final bool eventClosed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: participants.map((participant) {
          return ListTile(
            title: Text(participant.name),
            trailing: participant.blocked
                ? null
                : TrustBadgeButton(
                    keyName: 'badge-${participant.name}',
                    level: participant.level,
                    onTap: () {
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => TrustSheet(
                            userName: participant.name,
                            level: participant.level,
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

class ChatHeaderHarness extends StatelessWidget {
  const ChatHeaderHarness({required this.deleted, super.key});

  final bool deleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Text(deleted ? '익명' : '상대 유저'),
          if (!deleted)
            TrustBadgeButton(
              keyName: 'chat-badge',
              level: TrustLevel.certified,
              onTap: () {
                unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const TrustSheet(
                      userName: '상대 유저',
                      level: TrustLevel.certified,
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

class TrustLifecycleHarness extends StatefulWidget {
  const TrustLifecycleHarness({required this.realtimeEnabled, super.key});

  final bool realtimeEnabled;

  @override
  State<TrustLifecycleHarness> createState() => _TrustLifecycleHarnessState();
}

class _TrustLifecycleHarnessState extends State<TrustLifecycleHarness> {
  TrustSnapshot _snapshot = const TrustSnapshot(
    identityVerified: true,
    approvedCredentialCount: 0,
    attendanceRate: 90,
  );
  bool _pendingPartnerApproval = false;
  bool _showRenewalGuide = false;

  void _applyPending() {
    if (_pendingPartnerApproval) {
      _snapshot = const TrustSnapshot(
        identityVerified: true,
        approvedCredentialCount: 1,
        attendanceRate: 90,
      );
      _pendingPartnerApproval = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = deriveTrustLevel(_snapshot);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현재 등급: ${trustLevelLabel(level)}'),
          if (_showRenewalGuide) const Text('인증 갱신 안내'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (widget.realtimeEnabled) {
                  _snapshot = const TrustSnapshot(
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
                _snapshot = const TrustSnapshot(
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
                _snapshot = const TrustSnapshot(
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
                _snapshot = const TrustSnapshot(
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
                _snapshot = const TrustSnapshot(
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
