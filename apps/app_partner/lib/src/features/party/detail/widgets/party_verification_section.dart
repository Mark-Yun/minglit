import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyVerificationSection extends ConsumerWidget {
  const PartyVerificationSection({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(partyVerificationsProvider(partyId));

    return verificationsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Text(context.l10n.partyDetail_empty_verifications),
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
              title: context.l10n.common_button_edit,
              iconData: Icons.edit_outlined,
              onTap: () {
                // TODO(mark): Navigate to Edit Party (Verification Step)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('준비 중입니다.')),
                );
              },
            ),
          ],
        );
      },
      loading: () => const MinglitSkeleton(height: 80),
      error: (e, s) =>
          Text(context.l10n.reviewVerification_error_load(e.toString())),
    );
  }
}
