import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/my_tickets/logic/my_tickets_controller.dart';
import 'package:app_user/src/features/my_tickets/ui/my_ticket_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Fix #640: MyTicketsPage — main page with today event banner,
/// upcoming/past card lists, and empty state.
class MyTicketsPage extends ConsumerWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(myTicketsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 티켓')),
      body: MinglitAsyncValueWidget<MyTicketsState>(
        value: stateAsync,
        data: (state) {
          if (state.isEmpty) {
            return _EmptyState(
              onExploreTap: () {
                ref.read(homeCoordinatorProvider).goToHome();
              },
            );
          }

          return ListView(
            children: [
              // Today event banner
              if (state.todayEvent != null)
                _TodayBanner(
                  application: state.todayEvent!,
                  onQRTap: () => _onQRTap(ref, state.todayEvent!.ticketId),
                ),

              // Upcoming section
              if (state.upcoming.isNotEmpty) ...[
                const _SectionHeader(title: '다가오는 이벤트'),
                ...state.upcoming.map(
                  (app) => MyTicketCard(
                    application: app,
                    isPast: false,
                    onTap: () => _onCardTap(ref, app),
                    onQRTap: () => _onQRTap(ref, app.ticketId),
                  ),
                ),
              ],

              // Past section
              if (state.past.isNotEmpty) ...[
                const _SectionHeader(title: '지난 이벤트'),
                ...state.past.map(
                  (app) => MyTicketCard(
                    application: app,
                    isPast: true,
                    onTap: () => _onCardTap(ref, app),
                  ),
                ),
              ],

              const SizedBox(height: MinglitSpacing.large),
            ],
          );
        },
      ),
    );
  }

  void _onCardTap(WidgetRef ref, EventApplication application) {
    ref.read(homeCoordinatorProvider).pushEventDetail(application.eventId);
  }

  // Fix #852: Navigate to ticket QR via coordinator
  // — removes cross-feature import
  void _onQRTap(WidgetRef ref, String ticketId) {
    ref.read(homeCoordinatorProvider).pushTicketQR(ticketId);
  }
}

/// Empty state with CTA to explore events.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExploreTap});

  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '아직 티켓이 없어요',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '관심 있는 이벤트를 찾아보세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.large),
            FilledButton(
              onPressed: onExploreTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.xlarge,
                  vertical: MinglitSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MinglitSpacing.sm),
                ),
              ),
              // Fix #862: CTA typography should follow theme.titleMedium instead of a hardcoded font size.
              child: Text(
                '이벤트 둘러보기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today event banner shown at the top when there's an event starting today.
class _TodayBanner extends StatelessWidget {
  const _TodayBanner({required this.application, required this.onQRTap});

  final EventApplication application;

  // Fix #852: QR navigation callback — replaces direct TicketQRScreen import
  final VoidCallback onQRTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = application.event;
    final timeLabel = event != null
        ? '오늘 ${DateFormat('HH:mm').format(event.startTime)} 시작'
        : '오늘';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.medium,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(
            alpha: MinglitOpacity.activeChip,
          ),
          borderRadius: BorderRadius.circular(MinglitSpacing.sm),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(
              alpha: MinglitOpacity.placeholder,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(MinglitSpacing.small),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: MinglitSpacing.sm),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event?.title ?? event?.party?.title ?? '-',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    timeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MinglitSpacing.sm),

            // QR button
            TextButton(
              onPressed: onQRTap,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.sm,
                  vertical: MinglitSpacing.xsmall2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MinglitSpacing.small),
                ),
                textStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('입장 QR'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header for "다가오는 이벤트" / "지난 이벤트".
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: MinglitSpacing.screenEdge,
        right: MinglitSpacing.screenEdge,
        top: MinglitSpacing.large,
        bottom: MinglitSpacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}
