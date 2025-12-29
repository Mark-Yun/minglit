import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_list_preview_screen.g.dart';

/// **Partner List Preview Screen**
///
/// Displays a list of all active partners for development preview.
/// Tapping an item opens the [PartnerDetailView].
class PartnerListPreviewScreen extends ConsumerWidget {
  const PartnerListPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(previewPartnersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Preview List')),
      body: partnersAsync.when(
        data: (partners) {
          if (partners.isEmpty) {
            return const Center(child: Text('No active partners found.'));
          }
          return ListView.separated(
            itemCount: partners.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final partner = partners[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      partner.profileImageUrl != null
                          ? NetworkImage(partner.profileImageUrl!)
                          : null,
                  child:
                      partner.profileImageUrl == null
                          ? Text(partner.name[0])
                          : null,
                ),
                title: Text(partner.name),
                subtitle: Text(partner.introduction ?? 'No introduction'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  unawaited(
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder:
                            (context) => Scaffold(
                              appBar: AppBar(title: Text(partner.name)),
                              body: PartnerDetailView(partner: partner),
                            ),
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

/// Local provider to fetch partners for preview.
@riverpod
Future<List<Partner>> previewPartners(Ref ref) {
  return ref.read(partnerRepositoryProvider).getPartners();
}
