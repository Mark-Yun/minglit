import 'package:app_partner/src/logic/event_create_draft_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeDraftEventCard extends StatelessWidget {
  const HomeDraftEventCard({
    required this.draft,
    required this.partyName,
    required this.onResume,
    super.key,
  });

  final EventCreateDraft draft;
  final String? partyName;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updatedAt = DateFormat('yyyy-MM-dd HH:mm').format(draft.updatedAt);
    final title = draft.title.trim().isEmpty ? '작성 중인 이벤트' : draft.title;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: MinglitOpacity.muted,
            ),
            borderRadius: BorderRadius.circular(MinglitRadius.input),
          ),
          child: Icon(
            Icons.edit_note_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [
            if (partyName != null) partyName,
            '임시저장 · $updatedAt 마지막 수정',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onResume,
      ),
    );
  }
}
