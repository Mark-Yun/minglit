import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Sorts [TodayActiveEvent] items by state priority, then by start time.
///
/// Priority groups (highest first):
///   1. Active — CHECK_IN_READY, CHECKED_IN, MATCHING, RESULTS
///   2. Waiting — WAITING
///   3. Ended — ENDED
///
/// Within the same priority group, events are sorted by [Event.startTime]
/// ascending (earlier events first).
List<TodayActiveEvent> sortActiveEvents(
  List<TodayActiveEvent> events,
  Map<String, EventNowBarState> stateMap,
) {
  return [...events]..sort((a, b) {
    final priorityA = _statePriority(stateMap[a.event.id]);
    final priorityB = _statePriority(stateMap[b.event.id]);

    if (priorityA != priorityB) return priorityA.compareTo(priorityB);
    return a.event.startTime.compareTo(b.event.startTime);
  });
}

/// Lower number = higher priority.
int _statePriority(EventNowBarState? state) {
  return switch (state) {
    EventNowBarState.checkInReady => 0,
    EventNowBarState.checkedIn => 0,
    EventNowBarState.matching => 0,
    EventNowBarState.results => 0,
    EventNowBarState.waiting => 1,
    EventNowBarState.ended => 2,
    null => 1, // Unknown → treat as waiting.
  };
}

/// Wraps the event now bar with multi-event support.
///
/// When one event exists, displays the bar without additional chrome.
/// When two or more events exist, adds a count badge and dropdown icon.
/// Tapping the dropdown opens a bottom sheet for event selection.
class EventNowMultiStack extends ConsumerStatefulWidget {
  /// Creates an [EventNowMultiStack].
  const EventNowMultiStack({
    required this.events,
    super.key,
    this.onEventTap,
  });

  /// All today's active events.
  final List<TodayActiveEvent> events;

  /// Called when the user taps on an event (bar or bottom sheet selection).
  final void Function(TodayActiveEvent event)? onEventTap;

  @override
  ConsumerState<EventNowMultiStack> createState() =>
      _EventNowMultiStackState();
}

class _EventNowMultiStackState extends ConsumerState<EventNowMultiStack> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    // Collect resolved states for sorting.
    final stateMap = <String, EventNowBarState>{};
    for (final active in widget.events) {
      ref
          .watch(eventNowBarStateProvider(active))
          .whenData((s) => stateMap[active.event.id] = s);
    }

    final sorted = sortActiveEvents(widget.events, stateMap);
    final clampedIndex = _selectedIndex.clamp(0, sorted.length - 1);
    final current = sorted[clampedIndex];
    final hasMultiple = sorted.length > 1;

    return _EventNowMultiBar(
      activeEvent: current,
      eventCount: sorted.length,
      showDropdown: hasMultiple,
      onTap: () => widget.onEventTap?.call(current),
      onDropdownTap: hasMultiple
          ? () => _showEventListSheet(context, sorted, stateMap)
          : null,
    );
  }

  Future<void> _showEventListSheet(
    BuildContext context,
    List<TodayActiveEvent> sorted,
    Map<String, EventNowBarState> stateMap,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MinglitRadius.card),
        ),
      ),
      builder: (_) => _EventListSheet(
        events: sorted,
        stateMap: stateMap,
        selectedIndex: _selectedIndex.clamp(0, sorted.length - 1),
        onSelect: (index) {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop();
          final selected = sorted[index];
          widget.onEventTap?.call(selected);
        },
      ),
    );
  }
}

/// The mini-bar that shows the current event, with optional count badge
/// and dropdown icon for multi-event scenarios.
class _EventNowMultiBar extends ConsumerWidget {
  const _EventNowMultiBar({
    required this.activeEvent,
    required this.eventCount,
    required this.showDropdown,
    this.onTap,
    this.onDropdownTap,
  });

  final TodayActiveEvent activeEvent;
  final int eventCount;
  final bool showDropdown;
  final VoidCallback? onTap;
  final VoidCallback? onDropdownTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(eventNowBarStateProvider(activeEvent));
    final state = stateAsync.when(
      data: (s) => s,
      loading: () => EventNowBarState.waiting,
      error: (_, _) => EventNowBarState.waiting,
    );
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final dotColor = _dotColor(state);
    final statusLabel = _statusText(state);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: MinglitColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(MinglitRadius.card),
            topRight: Radius.circular(MinglitRadius.card),
          ),
          border: Border(
            top: BorderSide(
              color: MinglitColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: MinglitSpacing.sm),
            // Event title
            Flexible(
              child: Text(
                event.title ?? '이벤트',
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Status text
            Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.textSecondary,
              ),
            ),
            // Count badge + dropdown (multi-event only)
            if (showDropdown) ...[
              const SizedBox(width: MinglitSpacing.small),
              _CountBadge(count: eventCount),
              GestureDetector(
                onTap: onDropdownTap,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(MinglitSpacing.xsmall),
                  child: Icon(
                    Icons.expand_more,
                    color: MinglitColors.textSecondary,
                    size: MinglitIconSize.small,
                  ),
                ),
              ),
            ],
            if (!showDropdown) ...[
              const SizedBox(width: MinglitSpacing.small),
              const Icon(
                Icons.chevron_right,
                color: MinglitColors.textSecondary,
                size: MinglitIconSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small circular badge showing the number of active events.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.xsmall + 2,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: MinglitColors.primary,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Bottom sheet listing all active events for selection.
class _EventListSheet extends StatelessWidget {
  const _EventListSheet({
    required this.events,
    required this.stateMap,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<TodayActiveEvent> events;
  final Map<String, EventNowBarState> stateMap;
  final int selectedIndex;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MinglitColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.screenEdge,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '진행 중인 이벤트',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          ...List.generate(events.length, (i) {
            final active = events[i];
            final event = active.event;
            final state = stateMap[event.id];
            final isSelected = i == selectedIndex;

            return _EventListTile(
              title: event.title ?? '이벤트',
              statusLabel: _statusText(state ?? EventNowBarState.waiting),
              dotColor: _dotColor(state ?? EventNowBarState.waiting),
              isSelected: isSelected,
              onTap: () => onSelect(i),
            );
          }),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}

/// A single row in the event selection bottom sheet.
class _EventListTile extends StatelessWidget {
  const _EventListTile({
    required this.title,
    required this.statusLabel,
    required this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String statusLabel;
  final Color dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
          vertical: MinglitSpacing.sm,
        ),
        color: isSelected
            ? MinglitColors.primary.withValues(alpha: 0.05)
            : null,
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: MinglitSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: MinglitSpacing.small),
              const Icon(
                Icons.check,
                color: MinglitColors.primary,
                size: MinglitIconSize.xsmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- Shared helpers (duplicated from EventNowBar to avoid
// exposing privates) ---

Color _dotColor(EventNowBarState state) {
  return switch (state) {
    EventNowBarState.waiting => MinglitColors.textSecondary,
    EventNowBarState.checkInReady => MinglitColors.primary,
    EventNowBarState.checkedIn => MinglitColors.success,
    EventNowBarState.matching => MinglitColors.secondary,
    EventNowBarState.results => MinglitColors.primary,
    EventNowBarState.ended => MinglitColors.textSecondary,
  };
}

String _statusText(EventNowBarState state) {
  return switch (state) {
    EventNowBarState.waiting => '곧 시작',
    EventNowBarState.checkInReady => '체크인하세요',
    EventNowBarState.checkedIn => '체크인 완료',
    EventNowBarState.matching => '매칭 진행 중',
    EventNowBarState.results => '결과 확인',
    EventNowBarState.ended => '종료됨',
  };
}
