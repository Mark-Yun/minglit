import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

class PartyContactSummary extends StatelessWidget {
  const PartyContactSummary({
    required this.contactOptions,
    required this.enabledContactMethods,
    this.showError = false,
    super.key,
  });

  final Map<String, dynamic> contactOptions;
  final Set<String> enabledContactMethods;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (enabledContactMethods.isEmpty && showError) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          context.l10n.wizard_review_empty_contact,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (enabledContactMethods.contains('phone'))
          _buildInfoRow(
            context,
            Icons.phone_outlined,
            context.l10n.partyCreate_label_phone,
            contactOptions['phone'] as String? ?? '-',
          ),
        if (enabledContactMethods.contains('email'))
          _buildInfoRow(
            context,
            Icons.email_outlined,
            context.l10n.partyCreate_label_email,
            contactOptions['email'] as String? ?? '-',
          ),
        if (enabledContactMethods.contains('kakao'))
          _buildInfoRow(
            context,
            Icons.chat_bubble_outline,
            context.l10n.common_label_kakao,
            (contactOptions['kakao_open_chat'] ?? contactOptions['kakao'])
                    as String? ??
                '-',
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
