import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_phases/check_in_ready_content.dart';
import 'package:app_user/src/features/home/widgets/event_now_phases/checked_in_content.dart';
import 'package:app_user/src/features/home/widgets/event_now_phases/ended_content.dart';
import 'package:app_user/src/features/home/widgets/event_now_phases/matching_content.dart';
import 'package:app_user/src/features/home/widgets/event_now_phases/results_content.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

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
          data: _buildContent,
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: MinglitCircularProgressIndicator()),
          ),
          error: (_, _) => _buildContent(EventNowBarState.checkInReady),
        ),
      ),
    );
  }

  Widget _buildContent(EventNowBarState state) {
    return switch (state) {
      EventNowBarState.waiting ||
      EventNowBarState.checkInReady => CheckInReadyContent(
        activeEvent: activeEvent,
      ),
      EventNowBarState.checkedIn => CheckedInContent(
        activeEvent: activeEvent,
      ),
      // Fix #664: Phase 3 — matching vote content
      EventNowBarState.matching => MatchingContent(
        activeEvent: activeEvent,
      ),
      // Fix #665: Phase 4 — match results
      EventNowBarState.results => ResultsContent(
        activeEvent: activeEvent,
      ),
      // Fix #665: Phase 5 — ended, review + next event
      EventNowBarState.ended => EndedContent(
        activeEvent: activeEvent,
      ),
    };
  }
}
