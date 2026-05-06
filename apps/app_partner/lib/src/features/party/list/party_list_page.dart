import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/widgets/party_list_item.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #2200: AppBar info → help sheet 패턴 적용 (QR 아이콘 제거 — Checkin 탭 진입으로 대체)
const _kPartyHelpSections = [
  HelpSection(
    title: '파티가 뭔가요?',
    body: '소셜 이벤트를 기획하고 운영하는 단위예요. 파티 안에 여러 이벤트를 만들어 참가자를 모집할 수 있어요.',
  ),
  HelpSection(
    title: '이벤트와 파티의 차이는?',
    body: '파티는 큰 틀(브랜드·카테고리), 이벤트는 실제 모임 일정이에요. 파티 하나에 이벤트를 여러 개 만들 수 있어요.',
  ),
  HelpSection(
    title: '파티 상태는 어떻게 달라지나요?',
    body: '임시저장(draft) → 게시(published) 순이에요. 게시 상태여야 참가자가 이벤트를 발견하고 신청할 수 있어요.',
  ),
  HelpSection(
    title: '이벤트를 만들려면?',
    body: '파티를 게시한 뒤 파티 상세에서 "+ 이벤트 추가"를 눌러요. 체크인은 하단 체크인 탭에서 QR 스캔으로 진행해요.',
  ),
];

class PartyListPage extends ConsumerWidget {
  const PartyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partyListProvider);
    final coordinator = ref.read(partyListCoordinatorProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '파티 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 22,
            tooltip: '도움말',
            onPressed: () => showMinglitHelpSheet(
              context: context,
              title: '파티 관리 가이드',
              sections: _kPartyHelpSections,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: coordinator.goToCreate,
          ),
        ],
      ),
      body: MinglitAsyncValueWidget(
        value: partiesAsync,
        data: (parties) {
          if (parties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.party_mode_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  Text(
                    '등록된 파티가 없습니다.\n새로운 파티를 기획해보세요!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.large),
            itemCount: parties.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final party = parties[index];
              return PartyListItem(
                party: party,
                onTap: () => coordinator.goToDetail(party.id),
              );
            },
          );
        },
      ),
    );
  }
}
