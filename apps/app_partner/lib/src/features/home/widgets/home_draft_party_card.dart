import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeDraftPartyCard extends StatelessWidget {
  const HomeDraftPartyCard({
    required this.party,
    required this.onCreateEvent,
    super.key,
  });

  final Party party;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        leading: const Icon(Icons.storefront_outlined),
        title: Text(
          party.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '이벤트가 없습니다',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: MinglitButton.secondary(
          label: '이벤트 생성',
          size: MinglitButtonSize.small,
          expand: false,
          onPressed: onCreateEvent,
        ),
      ),
    );
  }
}
