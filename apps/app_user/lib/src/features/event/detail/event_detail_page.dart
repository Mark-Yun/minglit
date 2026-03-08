import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/open_in_app_dialog.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/utils/share_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'event_detail_content.dart';
part 'event_info_tile.dart';
part 'event_quill_viewer.dart';
part 'event_entry_conditions_section.dart';
part 'event_bottom_ticket_bar.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailControllerProvider(eventId));

    return Scaffold(
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) => _EventDetailContent(event: event),
      ),
      // ignore: use_minglit_async_value_widget, returns skeleton/shrink for bottomNavigationBar
      bottomNavigationBar: eventAsync.when(
        data: (event) => _BottomTicketBar(event: event),
        loading: () => const _BottomTicketBarSkeleton(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
