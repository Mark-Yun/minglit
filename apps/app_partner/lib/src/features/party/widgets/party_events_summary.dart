import 'package:app_partner/src/features/party/detail/widgets/event_list_item.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Events Summary**
///
/// Displays a list of events (instances) for a party.
/// Used in the Operation tab of Party Detail.
class PartyEventsSummary extends StatelessWidget {
  const PartyEventsSummary({
    required this.events,
    this.onEventTap,
    this.onCreatePressed,
    super.key,
  });

  final List<Event> events;
  final void Function(Event)? onEventTap;
  final VoidCallback? onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
            child: EventListItem(
              event: event,
              onTap: onEventTap != null ? () => onEventTap!(event) : () {},
            ),
          ),
        ),
        if (onCreatePressed != null)
          Padding(
            padding: const EdgeInsets.only(top: MinglitSpacing.xxsmall),
            child: AddActionCard(
              title: context.l10n.partyDetail_button_createEvent,
              subtitle: context.l10n.partyDetail_subtitle_createEvent,
              onTap: onCreatePressed!,
            ),
          ),
      ],
    );
  }
}
