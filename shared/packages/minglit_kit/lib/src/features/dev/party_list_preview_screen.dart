import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_list_preview_screen.g.dart';

/// **Party List Preview Screen**
///
/// Development screen to preview all available parties in the database.
class PartyListPreviewScreen extends ConsumerWidget {
  const PartyListPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(previewPartiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Party Preview List')),
      body: partiesAsync.when(
        data: (parties) {
          if (parties.isEmpty) {
            return const Center(child: Text('No active parties found.'));
          }
          return ListView.separated(
            itemCount: parties.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final party = parties[index];
              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.celebration, color: Colors.orange),
                ),
                title: Text(party.title),
                subtitle: Text(
                  'Partner: ${party.partnerId.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => PartyDetailView(party: party),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

@riverpod
Future<List<Party>> previewParties(Ref ref) {
  return ref.read(partyRepositoryProvider).getParties();
}
