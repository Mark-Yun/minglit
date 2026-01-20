import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_event_management_tab.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_info_tab.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_rule_management_tab.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyDetailPage extends ConsumerWidget {
  const PartyDetailPage({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final coordinator = ref.watch(partyDetailCoordinatorProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: MinglitAsyncValueWidget(
          value: partyAsync,
          data: (party) => NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // 1. Simple AppBar
              SliverAppBar(
                title: Text(party.title),
                pinned: true,
                centerTitle: true,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        coordinator.goToEditParty(party.id);
                      } else if (value == 'activate') {
                        unawaited(coordinator.activateParty(party.id, context));
                      } else if (value == 'deactivate') {
                        unawaited(
                          coordinator.deactivateParty(party.id, context),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: MinglitIconSize.small),
                            const SizedBox(width: MinglitSpacing.small),
                            Text(context.l10n.partyDetail_menu_edit),
                          ],
                        ),
                      ),
                      if (party.status == 'closed')
                        PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_arrow_outlined,
                                size: MinglitIconSize.small,
                              ),
                              const SizedBox(width: MinglitSpacing.small),
                              Text(context.l10n.partyDetail_menu_activate),
                            ],
                          ),
                        ),
                      if (party.status == 'active')
                        PopupMenuItem(
                          value: 'deactivate',
                          child: Row(
                            children: [
                              Icon(
                                Icons.archive_outlined,
                                size: MinglitIconSize.small,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: MinglitSpacing.small),
                              Text(
                                context.l10n.partyDetail_menu_deactivate,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // 2. TabBar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TabBar(
                        indicatorWeight: 3,
                        labelPadding: EdgeInsets.symmetric(horizontal: 12),
                        tabs: [
                          Tab(text: '이벤트 관리'),
                          Tab(text: '파티 정보'),
                          Tab(text: '입장 그룹 및 티켓'),
                        ],
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                // Tab 1: 이벤트 관리
                PartyEventManagementTab(party: party),
                // Tab 2: 파티 정보
                PartyInfoTab(party: party),
                // Tab 3: 입장 그룹 및 티켓
                PartyRuleManagementTab(party: party),
              ],
            ),
          ),
          error: (e, s) => Scaffold(
            appBar: MinglitTheme.simpleAppBar(title: ''),
            body: Center(
              child: Text(
                context.l10n.partyDetail_error_partyLoad(e.toString()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.child);

  final Widget child;

  @override
  double get minExtent => 50;
  @override
  double get maxExtent => 50;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
