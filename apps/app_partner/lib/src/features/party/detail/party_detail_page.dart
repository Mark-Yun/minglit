import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_detail_info_tab.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_detail_operation_tab.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart' hide partyEventsProvider;

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
      length: 2,
      child: Scaffold(
        body: partyAsync.when(
          data: (party) => NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // 1. Header with Image
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    party.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 8),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (party.imageUrl != null)
                        Image.network(party.imageUrl!, fit: BoxFit.cover)
                      else
                        Container(color: colorScheme.primaryContainer),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
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
                      TabBar(
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: context.l10n.partyDetail_tab_operation),
                          Tab(text: context.l10n.partyDetail_tab_info),
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
                // Tab 1: 운영 관리 (회차 및 티켓)
                PartyDetailOperationTab(party: party),
                // Tab 2: 파티 정보 (기획 상세)
                PartyDetailInfoTab(party: party),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
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
