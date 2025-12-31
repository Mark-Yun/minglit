import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/widgets/party_list_item.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyListPage extends ConsumerWidget {
  const PartyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyListAsync = ref.watch(partyListProvider);
    final coordinator = PartyListCoordinator(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('파티 관리'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: coordinator.goToCreate,
        icon: const Icon(Icons.add),
        label: const Text('새 파티 기획'),
      ),
      body: partyListAsync.when(
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            itemCount: parties.length,
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
        error: (e, s) => Center(child: Text('오류가 발생했습니다: $e')),
      ),
    );
  }
}
