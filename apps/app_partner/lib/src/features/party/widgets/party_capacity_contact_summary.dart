import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Capacity & Contact Summary**
///
/// Displays recruitment capacity and contact methods in a clean card.
/// Reused in Party Detail and Review steps.
class PartyCapacityContactSummary extends StatelessWidget {
  const PartyCapacityContactSummary({
    required this.minCount,
    required this.maxCount,
    required this.contactOptions,
    required this.enabledContactMethods,
    this.onEdit,
    this.showError = false,
    super.key,
  });

  final int minCount;
  final int maxCount;
  final Map<String, dynamic> contactOptions;
  final Set<String> enabledContactMethods;
  final VoidCallback? onEdit;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(
          color: showError
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.people_outline,
            context.l10n.partyCreate_label_capacity,
            '$minCount ~ $maxCount명',
          ),
          if (enabledContactMethods.isEmpty && showError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '연락처가 선택되지 않았습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            )
          else ...[
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
                '카카오톡',
                (contactOptions['kakao_open_chat'] ?? contactOptions['kakao'])
                        as String? ??
                    '-',
              ),
          ],
          if (onEdit != null) ...[
            const SizedBox(height: MinglitSpacing.small),
            const Divider(),
            const SizedBox(height: MinglitSpacing.xsmall),
            AddActionCard(
              title: '인원 및 연락처 수정',
              iconData: Icons.edit_outlined,
              onTap: onEdit!,
            ),
          ],
        ],
      ),
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
