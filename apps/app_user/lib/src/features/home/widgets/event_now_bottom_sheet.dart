import 'package:app_user/src/features/event/matching/widgets/matching_vote_content.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/widgets/ticket_qr_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the Event Now bottom sheet for a given active event.
///
/// Displays Phase 1 (check-in ready — QR code), Phase 2 (checked in —
/// confirmation + participant count), or Phase 3 (matching — vote content)
/// depending on [EventNowBarState].
Future<void> showEventNowBottomSheet(
  BuildContext context,
  WidgetRef ref,
  TodayActiveEvent activeEvent,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MinglitRadius.card),
      ),
    ),
    builder: (_) => EventNowBottomSheet(activeEvent: activeEvent),
  );
}

/// Bottom sheet content for the Event Now Bar tap action.
///
/// Renders different content based on the event's current phase:
/// - **Phase 1** (`checkInReady` / `waiting`):
///   QR code + event info + location link
/// - **Phase 2** (`checkedIn`):
///   Check-in confirmation + participant count + avatars
/// - **Phase 3** (`matching`):
///   MatchingVoteContent with vote count header
/// - **Phase 4** (`results`):
///   Match result profile cards (or empty state)
/// - **Phase 5** (`ended`):
///   Review prompt + next event recommendation
class EventNowBottomSheet extends ConsumerWidget {
  /// Creates an [EventNowBottomSheet].
  const EventNowBottomSheet({required this.activeEvent, super.key});

  /// The active event to display.
  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(
      eventNowBarStateProvider(activeEvent),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom,
        ),
        child: stateAsync.when(
          data: (state) => _buildContent(context, ref, state),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: MinglitCircularProgressIndicator()),
          ),
          error: (_, _) => _buildContent(
            context,
            ref,
            EventNowBarState.checkInReady,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    EventNowBarState state,
  ) {
    return switch (state) {
      EventNowBarState.waiting ||
      EventNowBarState.checkInReady => _CheckInReadyContent(
        activeEvent: activeEvent,
      ),
      EventNowBarState.checkedIn => _CheckedInContent(
        activeEvent: activeEvent,
      ),
      // Fix #664: Phase 3 — matching vote content
      EventNowBarState.matching => _MatchingContent(
        activeEvent: activeEvent,
      ),
      // Fix #665: Phase 4 — match results
      EventNowBarState.results => _ResultsContent(
        activeEvent: activeEvent,
      ),
      // Fix #665: Phase 5 — ended, review + next event
      EventNowBarState.ended => _EndedContent(
        activeEvent: activeEvent,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Phase 1: Check-in Ready — QR code + event info + location link
// ---------------------------------------------------------------------------

class _CheckInReadyContent extends ConsumerWidget {
  const _CheckInReadyContent({required this.activeEvent});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final ticketTokenAsync = ref.watch(
      eventTicketTokenProvider(event.id),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MinglitColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Event name
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.small),

          // Event time
          Text(
            _formatEventTime(event),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // QR Code
          ticketTokenAsync.when(
            data: (token) {
              if (token == null) {
                return _QRErrorWidget(eventId: event.id);
              }
              return TicketQRViewer(token: token);
            },
            loading: () => const SizedBox(
              height: 280,
              child: Center(child: MinglitCircularProgressIndicator()),
            ),
            error: (_, _) => _QRErrorWidget(eventId: event.id),
          ),

          const SizedBox(height: MinglitSpacing.large),

          // Location info + deeplink
          if (event.party?.location != null) ...[
            _LocationRow(location: event.party!.location!),
            const SizedBox(height: MinglitSpacing.medium),
          ],
        ],
      ),
    );
  }

  String _formatEventTime(Event event) {
    final dateFormat = DateFormat('M월 d일 HH:mm');
    return dateFormat.format(event.startTime);
  }
}

// ---------------------------------------------------------------------------
// Phase 2: Checked In — confirmation + participant count + avatars
// ---------------------------------------------------------------------------

class _CheckedInContent extends StatelessWidget {
  const _CheckedInContent({required this.activeEvent});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final participantCount = event.currentParticipants;
    final maxParticipants = event.maxParticipants;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MinglitColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Check icon
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: MinglitColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: MinglitColors.background,
              size: 36,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // Confirmation text
          Text(
            '체크인 완료!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),

          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Participant count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                color: MinglitColors.textSecondary,
                size: MinglitIconSize.small,
              ),
              const SizedBox(width: MinglitSpacing.small),
              Text(
                '참석자 $participantCount / $maxParticipants명',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MinglitColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // Participant avatars placeholder row
          _ParticipantAvatarRow(count: participantCount),

          const SizedBox(height: MinglitSpacing.xlarge),

          // Waiting message
          Text(
            '곧 매칭이 시작될 거예요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MinglitColors.textSecondary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 3: Matching — MatchingVoteContent + vote count header
// ---------------------------------------------------------------------------

// Fix #664: MATCHING 상태에서 MatchingVoteContent 임베드 + 남은 투표 수 표시
class _MatchingContent extends ConsumerWidget {
  const _MatchingContent({required this.activeEvent});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final voteCountAsync = ref.watch(myVoteCountProvider(event.id));
    final maxVoteAsync = ref.watch(maxVoteCountProvider(event.id));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.small),
          _buildVoteStatus(theme, voteCountAsync, maxVoteAsync),
          const SizedBox(height: MinglitSpacing.medium),
          // Fix #664: MatchingVoteContent needs bounded height for internal
          // Expanded + GridView. Use 60% of screen height as content area.
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: MatchingVoteContent(eventId: event.id),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteStatus(
    ThemeData theme,
    AsyncValue<int> voteCountAsync,
    AsyncValue<int> maxVoteAsync,
  ) {
    if (!voteCountAsync.hasValue || !maxVoteAsync.hasValue) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: MinglitCircularProgressIndicator(),
      );
    }

    final voteCount = voteCountAsync.value!;
    final maxVote = maxVoteAsync.value!;
    final remaining = maxVote - voteCount;
    final text = remaining > 0 ? '남은 투표: $remaining / $maxVote' : '투표 완료!';

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: remaining > 0 ? MinglitColors.secondary : MinglitColors.success,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 4: Results — match result profiles or empty state
// ---------------------------------------------------------------------------

// Fix #665: RESULTS 상태에서 매칭 결과 프로필 카드 또는 빈 상태 표시
class _ResultsContent extends ConsumerWidget {
  const _ResultsContent({required this.activeEvent});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final matchesAsync = ref.watch(myMatchesProvider(event.id));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          const SizedBox(height: MinglitSpacing.xlarge),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: MinglitColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: MinglitColors.background,
              size: 36,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '매칭 결과',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
          matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) return _buildEmptyResult(theme);
              return _buildMatchList(theme, matches);
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: MinglitCircularProgressIndicator()),
            ),
            error: (_, _) => _buildEmptyResult(theme),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }

  Widget _buildEmptyResult(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xlarge),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 48,
            color: MinglitColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '이번엔 아쉽지만, 다음 기회에!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(ThemeData theme, List<MatchPair> matches) {
    return Column(
      children: [
        Text(
          '${matches.length}명과 매칭되었어요!',
          style: theme.textTheme.titleSmall?.copyWith(
            color: MinglitColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        for (final match in matches) ...[
          _MatchResultCard(match: match),
          const SizedBox(height: MinglitSpacing.small),
        ],
      ],
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard({required this.match});

  final MatchPair match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: MinglitColors.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(
          color: MinglitColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: MinglitColors.primary.withValues(alpha: 0.1),
            backgroundImage: match.partnerProfileImage != null
                ? NetworkImage(match.partnerProfileImage!)
                : null,
            child: match.partnerProfileImage == null
                ? Icon(
                    Icons.person,
                    color: MinglitColors.primary.withValues(alpha: 0.6),
                  )
                : null,
          ),
          const SizedBox(width: MinglitSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.partnerName ?? '알 수 없음',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (match.partnerContact != null) ...[
                  const SizedBox(height: MinglitSpacing.xxsmall),
                  Text(
                    match.partnerContact!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MinglitColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.favorite,
            color: MinglitColors.primary,
            size: MinglitIconSize.small,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Phase 5: Ended — review + next event suggestion
// ---------------------------------------------------------------------------

// Fix #665: ENDED 상태에서 별점 리뷰 UI + 리뷰 CTA
class _EndedContent extends StatelessWidget {
  const _EndedContent({required this.activeEvent});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context) {
    final event = activeEvent.event;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          const SizedBox(height: MinglitSpacing.xlarge),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MinglitColors.textSecondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              color: MinglitColors.textSecondary,
              size: 36,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '이벤트가 종료되었어요',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
          Text(
            '이벤트는 어떠셨나요?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _StarRatingRow(),
          const SizedBox(height: MinglitSpacing.xlarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO(mark): Navigate to review screen (#665)
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('리뷰 작성하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.medium,
                ),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}

class _StarRatingRow extends StatefulWidget {
  const _StarRatingRow();

  @override
  State<_StarRatingRow> createState() => _StarRatingRowState();
}

class _StarRatingRowState extends State<_StarRatingRow> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => setState(() => _rating = starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= _rating ? Icons.star : Icons.star_border,
              size: 40,
              color: starIndex <= _rating
                  ? MinglitColors.secondary
                  : MinglitColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        );
      }),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: MinglitColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

/// Location row with name + "위치 안내 보기" button.
class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openLocationDeeplink(context),
      borderRadius: BorderRadius.circular(MinglitRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MinglitSpacing.small,
          horizontal: MinglitSpacing.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: MinglitColors.primary,
              size: MinglitIconSize.small,
            ),
            const SizedBox(width: MinglitSpacing.small),
            Flexible(
              child: Text(
                location.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MinglitColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: MinglitSpacing.small),
            Text(
              '위치 안내 보기',
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationDeeplink(BuildContext context) async {
    // Fix #663: Use geo: URI scheme for cross-platform map deeplink
    final uri = Uri.parse(
      'geo:${location.latitude},${location.longitude}'
      '?q=${Uri.encodeComponent(location.address)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도 앱을 열 수 없습니다')),
        );
      }
    }
  }
}

/// QR load failure widget with retry button.
class _QRErrorWidget extends ConsumerWidget {
  const _QRErrorWidget({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 280,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: MinglitColors.error,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            'QR 코드를 불러올 수 없습니다',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextButton.icon(
            onPressed: () => ref.invalidate(eventTicketTokenProvider(eventId)),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

/// Avatar row showing participant circles (max 5 + remaining count).
class _ParticipantAvatarRow extends StatelessWidget {
  const _ParticipantAvatarRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final displayCount = count.clamp(0, 5);
    final remaining = count - displayCount;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < displayCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: MinglitColors.primary.withValues(
                alpha: 0.1 + (i * 0.15),
              ),
              child: Icon(
                Icons.person,
                size: 16,
                color: MinglitColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: MinglitSpacing.small),
            child: Text(
              '+$remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Provider: Ticket token lookup by event ID
// ---------------------------------------------------------------------------

/// Fetches the user's [TicketToken] for a given event by scanning the
/// local ticket wallet.
///
/// Returns `null` if no matching token is found (e.g., not yet minted).
// ignore: specify_nonobvious_property_types, Reason: Type is inferred correctly by FutureProvider.family
final eventTicketTokenProvider = FutureProvider.family<TicketToken?, String>((
  ref,
  eventId,
) async {
  final wallet = ref.watch(ticketWalletRepositoryProvider);
  final ids = await wallet.listAllTicketIds();

  for (final id in ids) {
    final token = await wallet.getTicket(id);
    if (token != null && token.eventId == eventId) {
      return token;
    }
  }
  return null;
});
