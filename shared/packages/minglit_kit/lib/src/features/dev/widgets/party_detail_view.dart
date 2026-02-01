import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/logic/providers/event_feed_provider.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';

/// A detailed view of a Party.
class PartyDetailView extends ConsumerWidget {
  const PartyDetailView({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(context),
                  const SizedBox(height: MinglitSpacing.xlarge),
                  Text(
                    '다가오는 일정',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  _buildEventList(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          party.title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: theme.shadowColor.withValues(alpha: 0.54),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (party.imageUrl != null)
              Image.network(party.imageUrl!, fit: BoxFit.cover)
            else
              Container(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.1,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0),
                    theme.colorScheme.onSurface.withValues(alpha: 0.54),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    // Assuming description is simple text for now (DB has jsonb)
    final descMap = party.description;
    final text = descMap?['text'] as String? ?? '파티 소개가 없습니다.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        if (party.contactOptions['phone'] != null)
          Row(
            children: [
              Icon(
                Icons.phone,
                size: MinglitIconSize.xsmall,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: MinglitSpacing.small),
              Text(
                party.contactOptions['phone'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEventList(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(partyEventsProvider(party.id));

    return MinglitAsyncValueWidget(
      value: eventsAsync,
      data: (events) {
        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(MinglitRadius.small),
            ),
            child: const Center(child: Text('예정된 일정이 없습니다.')),
          );
        }
        return Column(
          children: events.map((e) => _buildEventCard(context, e)).toList(),
        );
      },
      error: (e, _) => Text('Error loading events: $e'),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM월 dd일 (E) HH:mm', 'ko_KR');
    final dateStr = dateFormat.format(event.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: ListTile(
        contentPadding: const EdgeInsets.all(MinglitSpacing.medium),
        title: Text(
          event.title ?? '정기 파티',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: MinglitSpacing.small),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: MinglitIconSize.xsmall * 0.8,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: MinglitSpacing.xxsmall),
                Text(dateStr, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: MinglitSpacing.xxsmall),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: MinglitIconSize.xsmall * 0.8,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: MinglitSpacing.xxsmall),
                Text(
                  '${event.currentParticipants} / ${event.maxParticipants}명',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(60, 36),
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
            ),
          ),
          child: const Text('예매'),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  final url = 'https://minglit.app/parties/${party.id}';
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크가 복사되었습니다')),
                  );
                },
                child: const Text('공유하기'),
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주최자에게 문의하기 (TBD)')),
                  );
                },
                child: const Text('문의하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
