import 'dart:async';

import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 수동 체크인 바텀시트.
///
/// 이름 또는 전화 뒷자리 4자리로 참가자를 검색하고 체크인 처리한다.
// Fix #1812: Phase 4 — 수동 체크인 시트 (검색 + AnimatedList)
class ManualCheckinSheet extends ConsumerStatefulWidget {
  const ManualCheckinSheet({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<ManualCheckinSheet> createState() => _ManualCheckinSheetState();
}

class _ManualCheckinSheetState extends ConsumerState<ManualCheckinSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  // Fix #1947: guard rapid taps — track ticket IDs with an in-flight RPC call.
  final Set<String> _inFlightTicketIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  List<CheckinParticipant> _filter(List<CheckinParticipant> all) {
    final q = _query;
    if (q.isEmpty) return all;
    // 순수 숫자 4자리 → 전화 뒷자리 매칭
    final isPhone = RegExp(r'^\d{4}$').hasMatch(q);
    return all.where((p) {
      if (isPhone) return p.phoneLast4 == q;
      return p.name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final participantsAsync = ref.watch(
      manualCheckinControllerProvider(widget.eventId),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MinglitRadius.card),
            ),
            child: Column(
              children: [
                // 드래그 핸들
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),

                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.screenEdge,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '수동 체크인',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                // 검색 입력
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.screenEdge,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '이름 또는 전화 뒷자리 4자리',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          MinglitRadius.input,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: MinglitSpacing.screenEdge,
                    right: MinglitSpacing.screenEdge,
                    bottom: 8,
                  ),
                  child: Text(
                    'QR 인식이 어려울 때 이름으로 체크인 처리',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const Divider(height: 1),

                // 참가자 목록
                Expanded(
                  child: participantsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '참가자 목록을 불러올 수 없습니다',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              manualCheckinControllerProvider(widget.eventId),
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                    data: (all) {
                      final filtered = _filter(all);
                      final unchecked = filtered
                          .where((p) => !p.isCheckedIn)
                          .toList();
                      final checked = filtered
                          .where((p) => p.isCheckedIn)
                          .toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            _query.isEmpty ? '참가자가 없습니다' : '검색 결과가 없습니다',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (unchecked.isNotEmpty) ...[
                            _SectionHeader(
                              '미체크인 (${unchecked.length}명)',
                              scheme: scheme,
                              theme: theme,
                            ),
                            ...unchecked.map(
                              (p) => _ParticipantRow(
                                key: ValueKey(p.id),
                                participant: p,
                                isLoading: _inFlightTicketIds.contains(
                                  p.ticketId,
                                ),
                                onCheckin:
                                    _inFlightTicketIds.contains(p.ticketId)
                                    ? null
                                    : () => _checkin(p),
                              ),
                            ),
                          ],
                          if (checked.isNotEmpty) ...[
                            _SectionHeader(
                              '체크인 완료 (${checked.length}명)',
                              scheme: scheme,
                              theme: theme,
                            ),
                            ...checked.map(
                              (p) => _ParticipantRow(
                                key: ValueKey(p.id),
                                participant: p,
                                onCheckin: null,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _checkin(CheckinParticipant participant) async {
    // Fix #1947: mark in-flight before any async gap to block duplicate taps.
    setState(() => _inFlightTicketIds.add(participant.ticketId));
    HapticFeedback.selectionClick();
    try {
      final result = await ref
          .read(manualCheckinControllerProvider(widget.eventId).notifier)
          .checkin(participant.ticketId);

      if (!mounted) return;

      if (result == 'already_checked_in') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${participant.name}님은 이미 체크인되었습니다')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('체크인 처리 중 오류가 발생했습니다')),
      );
    } finally {
      if (mounted) {
        setState(() => _inFlightTicketIds.remove(participant.ticketId));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {required this.scheme, required this.theme});

  final String label;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: MinglitSpacing.screenEdge,
        right: MinglitSpacing.screenEdge,
        top: 12,
        bottom: 4,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.onCheckin,
    this.isLoading = false,
    super.key,
  });

  final CheckinParticipant participant;
  final VoidCallback? onCheckin;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final initial = participant.name.isNotEmpty ? participant.name[0] : '?';

    return Semantics(
      label:
          '${participant.name}, '
          '전화 뒷자리 ${participant.phoneLast4}, '
          '${participant.isCheckedIn ? "체크인 완료" : "미체크인"}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
          vertical: 6,
        ),
        child: Row(
          children: [
            // 아바타
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              child: Text(
                initial,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 이름 + 전화 뒷자리
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (participant.phoneLast4.isNotEmpty)
                    Text(
                      '010-****-${participant.phoneLast4}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // 체크인 버튼 또는 완료 표시
            // Fix #1947: show spinner while in-flight to block duplicate taps.
            if (isLoading)
              const SizedBox.square(
                dimension: 44,
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (onCheckin != null)
              SizedBox(
                height: 44,
                child: Center(
                  child: FilledButton(
                    onPressed: onCheckin,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          MinglitRadius.button,
                        ),
                      ),
                    ),
                    child: const Text('체크인'),
                  ),
                ),
              )
            else
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(72, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MinglitRadius.button),
                  ),
                  foregroundColor: MinglitColors.success,
                  side: const BorderSide(color: MinglitColors.success),
                ),
                child: const Text('완료'),
              ),
          ],
        ),
      ),
    );
  }
}
