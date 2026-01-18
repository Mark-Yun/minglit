import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/repositories/party_repository.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_list_preview_screen.g.dart';

/// **Party List Preview Screen**
///
/// Development screen to preview all available parties in the database.
class PartyListPreviewScreen extends ConsumerWidget {
  const PartyListPreviewScreen({super.key});

  void _showDetail(BuildContext context, Party party) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(party.title),
          content: SingleChildScrollView(
            child: Text(party.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(previewPartiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Party Preview List')),
      body: partiesAsync.when(
        data: (parties) => ListView.builder(
          itemCount: parties.length,
          itemBuilder: (context, index) {
            final p = parties[index];
            return ListTile(
              title: Text(p.title),
              subtitle: Text(p.id),
              onTap: () => _showDetail(context, p),
            );
          },
        ),
        loading: () => const MinglitCircularProgressIndicator(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

@riverpod
Future<List<Party>> previewParties(Ref ref) {
  return ref.read(partyRepositoryProvider).getParties();
}
