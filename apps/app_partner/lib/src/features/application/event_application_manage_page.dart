import 'dart:async';

import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod/misc.dart';

part 'event_application_manage_tab.dart';
part 'event_application_manage_widgets.dart';

/// Event application management page — grouped by event with inline approve/reject.
class EventApplicationManagePage extends ConsumerStatefulWidget {
  const EventApplicationManagePage({super.key});

  @override
  ConsumerState<EventApplicationManagePage> createState() =>
      _EventApplicationManagePageState();
}

class _EventApplicationManagePageState
    extends ConsumerState<EventApplicationManagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(currentPartnerInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('신청관리'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대기중'),
            Tab(text: '승인됨'),
            Tab(text: '거절됨'),
          ],
        ),
      ),
      body: partnerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (partner) {
          if (partner == null) {
            return const Center(child: Text('파트너 정보를 불러올 수 없습니다'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _ApplicationTab(
                partnerId: partner.id,
                statusFilter: const ['pending', 'pending_review'],
                showActions: true,
              ),
              _ApplicationTab(
                partnerId: partner.id,
                statusFilter: const ['approved', 'paid'],
                showActions: false,
              ),
              _ApplicationTab(
                partnerId: partner.id,
                statusFilter: const ['rejected'],
                showActions: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Provider to fetch applications grouped by event for a partner.
final FutureProviderFamily<
  Map<Event, List<EventApplication>>,
  ({String partnerId, List<String> statusFilter})
>
eventApplicationsGroupedProvider = FutureProvider.family
    .autoDispose<
      Map<Event, List<EventApplication>>,
      ({String partnerId, List<String> statusFilter})
    >((ref, params) async {
      final eventRepo = ref.read(eventRepositoryProvider);

      // Fix #1597: getUpcomingEvents는 7일 제한 → getPartnerFutureEvents 사용
      // 신청관리는 모든 미래 이벤트의 pending 신청을 표시해야 함
      final events = await eventRepo.getPartnerFutureEvents(params.partnerId);

      final grouped = <Event, List<EventApplication>>{};

      // Fix #1597: chunk per-event fetches to ≤10 concurrent RPC calls.
      // getPartnerFutureEvents can return up to 500 events; firing all at once
      // saturates the PostgREST connection pool and triggers rate-limit errors.
      const chunkSize = 10;
      final allApps = <List<EventApplication>>[];
      for (var i = 0; i < events.length; i += chunkSize) {
        final end = i + chunkSize > events.length
            ? events.length
            : i + chunkSize;
        final chunkApps = await Future.wait(
          events
              .sublist(i, end)
              .map((e) => eventRepo.getApplicationsByEventId(e.id)),
        );
        allApps.addAll(chunkApps);
      }
      for (var i = 0; i < events.length; i++) {
        final filtered = allApps[i]
            .where((a) => params.statusFilter.contains(a.status))
            .toList();
        if (filtered.isNotEmpty) {
          grouped[events[i]] = filtered;
        }
      }

      return grouped;
    });
