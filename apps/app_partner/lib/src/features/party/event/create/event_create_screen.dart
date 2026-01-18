import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/event/create/tabs/event_create_info_tab.dart';
import 'package:app_partner/src/features/party/event/create/tabs/event_create_operation_tab.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventCreateScreen extends ConsumerStatefulWidget {
  const EventCreateScreen({required this.partyId, super.key});

  final String partyId;

  @override
  ConsumerState<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends ConsumerState<EventCreateScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize controller state from Party data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final party = await ref.read(partyDetailProvider(widget.partyId).future);
      final tickets = await ref.read(
        partyTicketsProvider(widget.partyId).future,
      );
      Location? location;
      if (party.locationId != null) {
        location = await ref.read(
          locationDetailProvider(party.locationId).future,
        );
      }

      if (mounted) {
        ref
            .read(eventCreateControllerProvider(widget.partyId).notifier)
            .initWithParty(
              party: party,
              templates: tickets,
              location: location,
            );
      }
    });
  }

  Future<void> _submit() async {
    final notifier = ref.read(
      eventCreateControllerProvider(widget.partyId).notifier,
    );

    await notifier.submit();

    final state = ref.read(eventCreateControllerProvider(widget.partyId));
    if (state.status.hasValue && !state.status.hasError && mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새로운 회차가 성공적으로 생성되었습니다.')));
    } else if (state.status.hasError && mounted) {
      handleMinglitError(context, state.status.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventCreateControllerProvider(widget.partyId));
    final notifier = ref.read(
      eventCreateControllerProvider(widget.partyId).notifier,
    );
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.eventCreate_title),
          bottom: TabBar(
            tabs: [
              const Tab(text: '운영 및 티켓'),
              Tab(text: context.l10n.partyDetail_tab_info),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Schedule & Tickets
                  EventCreateOperationTab(state: state, notifier: notifier),

                  // Tab 2: Event Details (Summary Based)
                  EventCreateInfoTab(
                    state: state,
                    notifier: notifier,
                    partyId: widget.partyId,
                  ),
                ],
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: state.status.isLoading ? null : _submit,
                  child: state.status.isLoading
                      ? const Text('회차 생성 중...')
                      : const Text('회차 생성 완료'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
