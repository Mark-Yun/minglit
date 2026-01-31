import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:app_user/src/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailControllerProvider(eventId));

    return Scaffold(
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) => _EventDetailContent(event: event),
      ),
      bottomNavigationBar: eventAsync.maybeWhen(
        data: (event) => _BottomTicketBar(event: event),
        orElse: () => null,
      ),
    );
  }
}

class _EventDetailContent extends ConsumerWidget {
  const _EventDetailContent({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final party = event.party;
    final partner = party?.partner;
    final location = event.location ?? party?.location;
    final eventTitle = party?.title ?? event.title ?? '제목 없음';

    // Date Format
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko_KR',
    ).format(event.startTime);

    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(eventDetailControllerProvider(event.id).future);
      },
      child: CustomScrollView(
        slivers: [
          // 1. Hero Image Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: MinglitImageCarousel(
                imageUrls: party?.imageUrls ?? [],
              ),
            ),
            leading: BackButton(color: theme.colorScheme.onPrimary),
            actions: [
              IconButton(
                onPressed: () {
                  unawaited(
                    ShareUtils.shareEvent(
                      eventTitle: eventTitle,
                      eventId: event.id,
                    ),
                  );
                },
                icon: Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.onPrimary,
                ),
                tooltip: '공유하기',
              ),
              Padding(
                padding: const EdgeInsets.only(right: MinglitSpacing.small),
                child: MinglitSocialButton(
                  targetId: event.partyId, // Like the party
                  targetType: SocialTargetType.party,
                  interactionType: SocialInteractionType.like,
                  activeColor: theme.colorScheme.onPrimary,
                  inactiveColor: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
            backgroundColor: theme.colorScheme.primary,
          ),

          // 2. Main Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Row
                  if (partner != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: MinglitRadius.input, // 12
                          backgroundImage: partner.profileImageUrl != null
                              ? NetworkImage(partner.profileImageUrl!)
                              : null,
                          child: partner.profileImageUrl == null
                              ? const Icon(
                                  Icons.store,
                                  size: MinglitIconSize.xsmall,
                                )
                              : null,
                        ),
                        const SizedBox(width: MinglitSpacing.small),
                        Text(
                          partner.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                  ],

                  // Title
                  Text(
                    eventTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),

                  // Info Cards
                  _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    title: dateLabel,
                    subtitle:
                        '${event.endTime.difference(event.startTime).inHours}'
                        '시간 진행',
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    title: location?.name ?? '장소 미정',
                    subtitle: location?.address ?? '주소 정보 없음',
                  ),

                  const Divider(height: MinglitSpacing.xlarge),

                  // 3. Description (Rich Text)
                  Text(
                    '상세 소개',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  _QuillViewer(description: party?.description ?? {}),

                  const SizedBox(height: MinglitSpacing.xlarge),

                  // 4. Entry Conditions
                  _EntryConditionsSection(event: event),

                  const SizedBox(
                    height: MinglitSpacing.xlarge * 4,
                  ), // Bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.small),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(MinglitRadius.small),
          ),
          child: Icon(
            icon,
            size: MinglitIconSize.small,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: MinglitSpacing.medium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuillViewer extends StatelessWidget {
  const _QuillViewer({required this.description});

  final Map<String, dynamic> description;

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const Text('상세 소개 정보가 없습니다.');

    final controller = QuillController(
      document: Document.fromJson(description['ops'] as List),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    return QuillEditor.basic(controller: controller);
  }
}

class _EntryConditionsSection extends StatelessWidget {
  const _EntryConditionsSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryGroups = event.entryGroups ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '참여 자격',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        if (entryGroups.isEmpty)
          const Text('별도의 참여 제한이 없습니다.')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entryGroups.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              final group = entryGroups[index];
              return Container(
                padding: const EdgeInsets.all(MinglitSpacing.small),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(MinglitRadius.small),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: EntryGroupDetail(group: group.toTemplate()),
              );
            },
          ),
      ],
    );
  }
}

class _BottomTicketBar extends ConsumerWidget {
  const _BottomTicketBar({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final admissionAsync = ref.watch(eventAdmissionControllerProvider(event));

    final lowestPrice = event.tickets?.fold<int?>(
      null,
      (min, t) => min == null || t.price < min ? t.price : min,
    );

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최저가', style: theme.textTheme.labelSmall),
                Text(
                  lowestPrice != null
                      ? '${NumberFormat('#,###').format(lowestPrice)}원~'
                      : '가격 미정',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: MinglitSpacing.large),
            Expanded(
              child: MinglitAsyncValueWidget(
                value: admissionAsync,
                data: (state) => _buildActionButton(context, ref, state),
                loading: () => const ElevatedButton(
                  onPressed: null,
                  child: MinglitCircularProgressIndicator(
                    size: 20,
                  ),
                ),
                error: (e, _) => ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
                  child: const Text('오류 발생'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    AdmissionState state,
  ) {
    final theme = Theme.of(context);
    var text = '참가 신청하기';
    VoidCallback? onPressed;
    Color? backgroundColor;

    switch (state.status) {
      case EventAdmissionStatus.guest:
        text = '로그인하고 신청하기';
        onPressed = () {
          final currentPath = GoRouterState.of(context).uri.toString();
          ref
              .read(authCoordinatorProvider)
              .goToLogin(context, from: currentPath);
        };
      case EventAdmissionStatus.identityRequired:
        text = '본인인증 후 신청하기';
        onPressed = () async {
          final success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const IdentityVerificationScreen(),
              fullscreenDialog: true,
            ),
          );
          if (success ?? false) {
            ref.invalidate(eventAdmissionControllerProvider(event));
          }
        };
      case EventAdmissionStatus.qualificationRequired:
        text = '신청하기';
        onPressed = () async {
          // Open Ticket Sheet, it will show which ticket requires qualification
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TicketSelectionSheet(event: event),
          );
          // Refresh state as user might have applied
          ref.invalidate(eventAdmissionControllerProvider(event));
        };
      case EventAdmissionStatus.notEligible:
        text = state.ineligibleReason ?? '참여 조건 미달';
        onPressed = null; // Disabled
        backgroundColor = theme.colorScheme.outline;
      case EventAdmissionStatus.eligible:
        text = '참가 신청하기';
        onPressed = () {
          unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TicketSelectionSheet(event: event),
            ),
          );
        };
      case EventAdmissionStatus.pendingPayment:
        text = '결제 계속하기';
        onPressed = () {
          unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TicketSelectionSheet(event: event),
            ),
          );
        };
      case EventAdmissionStatus.applied:
        text = '이미 신청한 이벤트';
        onPressed = () {
          handleMinglitError(
            context,
            const MinglitUserException(
              '이미 신청이 완료된 이벤트입니다.\n마이페이지에서 티켓을 확인해주세요.',
            ),
          );
        };
      case EventAdmissionStatus.rejected:
        text = '심사 반려 (사유 확인)';
        backgroundColor = theme.colorScheme.error;
        onPressed = () async {
          final confirmed = await context.showMinglitConfirm(
            title: '심사 결과 안내',
            message:
                '반려 사유: ${state.rejectionReason ?? "정보 부족"}\n\n'
                '기존 신청을 취소하고 다시 신청하시겠습니까?',
            confirmLabel: '다시 신청하기',
            cancelLabel: '닫기',
          );

          if (confirmed && context.mounted) {
            final loading = ref.read(globalLoadingControllerProvider.notifier)
              ..show();
            try {
              await ref
                  .read(eventRepositoryProvider)
                  .deleteApplication(
                    eventId: event.id,
                    userId: state.user!.id,
                  );
              // Refresh state
              ref.invalidate(eventAdmissionControllerProvider(event));
              if (context.mounted) {
                unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TicketSelectionSheet(event: event),
                  ),
                );
              }
            } finally {
              loading.hide();
            }
          }
        };
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      child: Text(text),
    );
  }
}
