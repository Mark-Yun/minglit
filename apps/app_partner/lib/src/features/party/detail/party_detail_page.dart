import 'dart:async';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/create/ticket_template_create_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/widgets/event_list_item.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart' hide partyEventsProvider;

class PartyDetailPage extends ConsumerWidget {
  const PartyDetailPage({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final eventsAsync = ref.watch(partyEventsProvider(partyId));
    final ticketsAsync = ref.watch(partyTicketsProvider(partyId));
    final coordinator = ref.watch(partyDetailCoordinatorProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: partyAsync.when(
        data: (party) => CustomScrollView(
          slivers: [
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
                      unawaited(coordinator.deactivateParty(party.id, context));
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: MinglitIconSize.small),
                          SizedBox(width: MinglitSpacing.small),
                          Text('파티 정보 수정'),
                        ],
                      ),
                    ),
                    if (party.status == 'closed')
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_arrow_outlined,
                              size: MinglitIconSize.small,
                            ),
                            SizedBox(width: MinglitSpacing.small),
                            Text('파티 다시 활성화'),
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
                              '파티 비활성화 (보관)',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // 2. Party Info Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.people_outline,
                          label:
                              '${party.minConfirmedCount}'
                              '~${party.maxParticipants}명',
                        ),
                      ],
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      '참가 자격 (인증)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    _VerificationSection(partyId: party.id),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      '장소 정보',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    _LocationSection(
                      locationId: party.locationId,
                      partyId: party.id,
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      '장소 상세',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    _LocationDetailSection(locationId: party.locationId),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      '개설된 회차 (이벤트)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                  ],
                ),
              ),
            ),

            // 3. Events List
            eventsAsync.when(
              data: (events) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < events.length) {
                        final event = events[index];
                        return EventListItem(
                          event: event,
                          onTap: () => coordinator.goToEventDetail(
                            party.id,
                            event.id,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: MinglitSpacing.xxsmall,
                        ),
                        child: AddActionCard(
                          title: '새로운 회차 개설하기',
                          subtitle: '새로운 날짜와 시간에 파티를 열어보세요.',
                          onTap: () => coordinator.goToCreateEvent(party.id),
                        ),
                      );
                    },
                    childCount: events.length + 1,
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('이벤트 로드 실패: $e')),
              ),
            ),

            // 4. Registered Tickets Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  MinglitSpacing.medium,
                  MinglitSpacing.xlarge,
                  MinglitSpacing.medium,
                  MinglitSpacing.small,
                ),
                child: Text(
                  '등록된 티켓 현황',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),

            ticketsAsync.when(
              data: (tickets) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                sliver: SliverToBoxAdapter(
                  child: TicketListView(
                    tickets: tickets,
                    onCreatePressed: () async {
                      final newTicket =
                          await Navigator.of(context).push<Ticket>(
                            MaterialPageRoute(
                              builder: (_) => const TicketTemplateCreatePage(),
                            ),
                          );

                      if (newTicket != null) {
                        final loading =
                            ref.read(globalLoadingControllerProvider.notifier)
                              ..show();
                        try {
                          final repo = ref.read(ticketRepositoryProvider);
                          await repo.createTicket(
                            newTicket.copyWith(partyId: partyId, eventId: null),
                          );
                          ref.invalidate(partyTicketsProvider(partyId));

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('티켓 템플릿이 추가되었습니다.'),
                              ),
                            );
                          }
                        } on Exception catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '일시적인 오류로 티켓을 생성하지 못했습니다. 잠시 후 다시 시도해주세요.',
                                ),
                              ),
                            );
                          }
                        } finally {
                          loading.hide();
                        }
                      }
                    },
                    onTicketTap: (ticket) {
                      // Navigate to appropriate detail/edit if needed
                    },
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('티켓 로드 실패: $e')),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: MinglitSpacing.xlarge),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('파티 로드 실패: $e')),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: MinglitIconSize.xsmall,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends ConsumerWidget {
  const _LocationSection({required this.locationId, required this.partyId});
  final String? locationId;
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locationId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Column(
            children: [
              const Text('지정된 장소 정보가 없습니다.'),
              const SizedBox(height: MinglitSpacing.medium),
              _buildEditButton(context, ref),
            ],
          ),
        ),
      );
    }

    final locationAsync = ref.watch(locationDetailProvider(locationId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return locationAsync.when(
      data: (loc) {
        if (loc == null) return const Text('장소 정보를 불러올 수 없습니다.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                child: LocationMap(
                  latitude: loc.latitude,
                  longitude: loc.longitude,
                ),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              loc.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              loc.address,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            _buildEditButton(context, ref),
          ],
        );
      },
      loading: () => const MinglitSkeleton(height: 180),
      error: (e, s) => Text('장소 로드 실패: $e'),
    );
  }

  Widget _buildEditButton(BuildContext context, WidgetRef ref) {
    return AddActionCard(
      title: '장소 수정하기',
      iconData: Icons.edit_location_alt_outlined,
      onTap: () => unawaited(_handleEditLocation(context, ref)),
    );
  }

  Future<void> _handleEditLocation(BuildContext context, WidgetRef ref) async {
    final coordinator = ref.read(partyDetailCoordinatorProvider);
    final newLocation = await coordinator.goToLocationSearch(context);
    if (newLocation != null) {
      final loading =
          ref.read(globalLoadingControllerProvider.notifier)..show();
      try {
        final party = await ref.read(partyDetailProvider(partyId).future);
        final locationRepo = ref.read(locationRepositoryProvider);
        final savedLocation = await locationRepo.createLocation(
          newLocation.copyWith(partnerId: party.partnerId),
        );

        final partyRepo = ref.read(partyRepositoryProvider);
        await partyRepo.updatePartyLocation(partyId, savedLocation.id);

        ref.invalidate(partyDetailProvider(partyId));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장소가 수정되었습니다.')),
          );
        }
      } on Exception catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장소 정보를 수정하지 못했습니다.')),
          );
        }
      } finally {
        loading.hide();
      }
    }
  }
}

class _VerificationSection extends ConsumerWidget {
  const _VerificationSection({required this.partyId});
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(partyVerificationsProvider(partyId));

    return verificationsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(MinglitSpacing.medium),
              child: Text('설정된 참가 자격이 없습니다 (누구나 참여 가능)'),
            ),
          );
        }
        return Column(
          children: [
            ...list.map(
              (v) => VerificationSelectCard(
                verification: v,
                isSelected: false,
                isReadOnly: true,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            AddActionCard(
              title: '참가 자격 수정하기',
              iconData: Icons.edit_outlined,
              onTap: () {
                // TODO(mark): Navigate to Edit Party (Verification Step)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('참가 자격 수정 기능 준비 중입니다.')),
                );
              },
            ),
          ],
        );
      },
      loading: () => const MinglitSkeleton(height: 80),
      error: (e, s) => Text('인증 정보 로드 실패: $e'),
    );
  }
}

class _LocationDetailSection extends ConsumerWidget {
  const _LocationDetailSection({required this.locationId});
  final String? locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locationId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(MinglitSpacing.medium),
          child: Text('장소 정보가 없어 상세 내용을 표시할 수 없습니다.'),
        ),
      );
    }

    final locationAsync = ref.watch(locationDetailProvider(locationId));

    return locationAsync.when(
      data: (loc) {
        if (loc == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loc.addressDetail != null && loc.addressDetail!.isNotEmpty)
              _buildDetailItem(
                context,
                Icons.apartment,
                '상세 주소',
                loc.addressDetail!,
              ),
            if (loc.directionsGuide != null && loc.directionsGuide!.isNotEmpty)
              _buildDetailItem(
                context,
                Icons.directions,
                '오시는 길',
                loc.directionsGuide!,
              ),
            if ((loc.addressDetail == null || loc.addressDetail!.isEmpty) &&
                (loc.directionsGuide == null || loc.directionsGuide!.isEmpty))
              const Padding(
                padding: EdgeInsets.only(bottom: MinglitSpacing.medium),
                child: Text('등록된 상세 정보가 없습니다.'),
              ),
            AddActionCard(
              title: '장소 상세 수정하기',
              iconData: Icons.edit_note,
              onTap: () => _showEditSheet(context, ref, loc),
            ),
          ],
        );
      },
      loading: () => const MinglitSkeleton(height: 100),
      error: (e, s) => Text('상세 정보 로드 실패: $e'),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: MinglitSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(content, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Location loc) {
    final detailController = TextEditingController(text: loc.addressDetail);
    final guideController = TextEditingController(text: loc.directionsGuide);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '장소 상세 정보 수정',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                  TextFormField(
                    controller: detailController,
                    decoration: const InputDecoration(
                      labelText: '상세 주소 (층/호수)',
                      hintText: '예: 2층 201호',
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  TextFormField(
                    controller: guideController,
                    decoration: const InputDecoration(
                      labelText: '오시는 길 안내',
                      hintText: '예: 1번 출구에서 직진 50m',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: MinglitSpacing.xlarge),
                  ElevatedButton(
                    onPressed: () {
                      unawaited(() async {
                        try {
                          final repo = ref.read(locationRepositoryProvider);
                          await repo.updateLocationDetails(
                            locationId: loc.id,
                            addressDetail: detailController.text,
                            directionsGuide: guideController.text,
                          );
                          ref.invalidate(locationDetailProvider(loc.id));
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('장소 상세 정보가 수정되었습니다.'),
                              ),
                            );
                          }
                        } on Exception catch (e) {
                          debugPrint('Update failed: $e');
                        }
                      }());
                    },
                    child: const Text('저장하기'),
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
