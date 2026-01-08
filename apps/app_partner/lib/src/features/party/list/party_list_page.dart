import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/widgets/party_list_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyListPage extends ConsumerWidget {
  const PartyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partyListProvider);
    final coordinator = PartyListCoordinator(context);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '파티 기획 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/parties/create'),
          ),
        ],
      ),
      body: partiesAsync.when(
        data: (List<Party> parties) {
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            Center(child: Text('오류가 발생했습니다: $e')),
      ),
    );
  }
}
