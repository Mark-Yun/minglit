import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/open_in_app_dialog.dart';
import 'package:app_user/src/features/event/detail/report_bottom_sheet.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:app_user/src/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'event_bottom_ticket_bar.dart';
part 'event_detail_content.dart';
part 'event_detail_content_skeleton.dart';
part 'event_entry_conditions_section.dart';
part 'event_info_tile.dart';
part 'event_quill_viewer.dart';
part 'event_refund_policy_section.dart';
part 'event_verification_section.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailControllerProvider(eventId));

    // Track event_viewed once when event data loads successfully
    ref.listen(eventDetailControllerProvider(eventId), (prev, next) {
      if (prev?.hasValue != true && next.hasValue) {
        StatsigAnalytics.logEvent(
          MingLitEvent.eventViewed,
          metadata: {'event_id': eventId},
        );
      }
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: MinglitAsyncValueWidget(
              value: eventAsync,
              data: (event) => _EventDetailContent(event: event),
              loading: () => const _EventDetailContentSkeleton(),
            ),
          ),
          // ignore: use_minglit_async_value_widget, returns skeleton/shrink for bottom bar
          eventAsync.when(
            data: (event) => _BottomTicketBar(event: event),
            loading: () => const _BottomTicketBarSkeleton(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
