import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyLocationSection extends ConsumerWidget {
  const PartyLocationSection({
    required this.locationId,
    required this.partyId,
    super.key,
  });

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
      final loading = ref.read(globalLoadingControllerProvider.notifier)
        ..show();
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
      } on Object catch (e, st) {
        if (context.mounted) {
          handleMinglitError(context, e, st);
        }
      } finally {
        loading.hide();
      }
    }
  }
}

class PartyLocationDetailSection extends ConsumerWidget {
  const PartyLocationDetailSection({required this.locationId, super.key});

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
