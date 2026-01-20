import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_template_manage_screen.g.dart';

@riverpod
Future<List<TicketTemplate>> partyTicketTemplates(Ref ref, String partyId) {
  return ref
      .read(ticketRepositoryProvider)
      .getTicketTemplatesByPartyId(partyId);
}

class TicketTemplateManageScreen extends ConsumerWidget {
  const TicketTemplateManageScreen({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(partyTicketTemplatesProvider(partyId));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '티켓 템플릿 관리'),
      body: MinglitAsyncValueWidget<List<TicketTemplate>>(
        value: templatesAsync,
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('등록된 티켓 템플릿이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            itemCount: templates.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              return _TemplateCard(template: templates[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO(mark): Implement Create Template Flow
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('템플릿 추가 기능은 준비 중입니다.')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final TicketTemplate template;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            template.description ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: MinglitSpacing.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatter.format(template.price)}원',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '기본 수량: ${template.quantity}매',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
