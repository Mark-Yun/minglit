import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_now_provider.dart';
import 'package:app_user/src/features/event/detail/open_in_app_dialog.dart';
import 'package:app_user/src/features/event/detail/report_bottom_sheet.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

export 'package:app_user/src/features/event/detail/event_detail_now_provider.dart';

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
      body: AnimatedSwitcher(
        duration: MinglitAnimation.medium,
        child: eventAsync.when(
          data: (event) => Column(
            key: const ValueKey('event_detail_data'),
            children: [
              Expanded(child: _EventDetailContent(event: event)),
              _BottomTicketBar(event: event),
            ],
          ),
          loading: () => const Column(
            key: ValueKey('event_detail_loading'),
            children: [
              Expanded(child: _EventDetailContentSkeleton()),
              _BottomTicketBarSkeleton(),
            ],
          ),
          error: (e, st) => Center(
            key: const ValueKey('event_detail_error'),
            child: MinglitErrorState(
              title: '이벤트를 불러올 수 없습니다',
              subtitle: e.toString(),
              onRetry: () =>
                  ref.invalidate(eventDetailControllerProvider(eventId)),
            ),
          ),
        ),
      ),
    );
  }
}
