import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_detail_page.g.dart';

/// Fetches a partner by ID for the detail page.
@riverpod
Future<Partner?> partnerDetail(Ref ref, {required String partnerId}) {
  return ref.read(partnerRepositoryProvider).getPartnerById(partnerId);
}

/// Partner detail page that fetches and displays partner information.
class PartnerDetailPage extends ConsumerWidget {
  const PartnerDetailPage({required this.partnerId, super.key});

  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(partnerDetailProvider(partnerId: partnerId));

    return Scaffold(
      appBar: AppBar(
        title:
            partnerAsync.whenOrNull(data: (p) => Text(p?.name ?? '')) ??
            const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: MinglitAsyncValueWidget(
        value: partnerAsync,
        data: (partner) {
          if (partner == null) {
            return const Center(child: Text('파트너를 찾을 수 없습니다.'));
          }
          // Fix #634: home_coordinator 직접 참조 → partner_coordinator 전환
          final coordinator = ref.read(partnerCoordinatorProvider);
          return PartnerDetailView(
            partner: partner,
            onEventTap: (event) => coordinator.pushEventDetail(event.id),
            onMoreEventsTap: () => coordinator.pushPartnerEvents(
              partnerId: partnerId,
              partnerName: partner.name,
            ),
          );
        },
      ),
    );
  }
}
