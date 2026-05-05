import 'package:app_partner/src/features/party/event/widgets/event_application_list_view.dart';
import 'package:flutter/material.dart';

/// Full-page wrapper for [EventApplicationListView] with an AppBar.
///
/// Navigated to from [EventDetailPage] — replaces the old inline tab.
// Fix #2224: Tab 구조 폐기 — 참가 신청 심사를 별도 라우트(EventApplicationListRoute)로 분리
class EventApplicationListPage extends StatelessWidget {
  const EventApplicationListPage({
    required this.eventId,
    this.groupId,
    super.key,
  });

  final String eventId;

  /// Optional entry-group filter. When set, only applications for tickets
  /// belonging to this entry group are shown.
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('참가 신청')),
      body: EventApplicationListView(eventId: eventId, groupId: groupId),
    );
  }
}
