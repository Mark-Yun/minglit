import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/widgets/party_list_item.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #2200: AppBar info → help sheet 패턴 적용 (QR 아이콘 제거 — Checkin 탭 진입으로 대체)
const _kPartyHelpSections = [
  HelpSection(
    title: '파티가 뭔가요?',
    body: '소셜 이벤트를 기획하고 운영하는 단위예요. 파티 안에 여러 이벤트를 만들어 참가자를 모집할 수 있어요.',
  ),
  HelpSection(
    title: '이벤트와 파티의 차이는?',
    body: '파티는 큰 틀(브랜드·카테고리), 이벤트는 실제 모임 일정이에요. 파티 하나에 이벤트를 여러 개 만들 수 있어요.',
  ),
  HelpSection(
    title: '파티 상태는 어떻게 달라지나요?',
    body: '임시저장(draft) → 게시(published) 순이에요. 게시 상태여야 참가자가 이벤트를 발견하고 신청할 수 있어요.',
  ),
  HelpSection(
    title: '이벤트를 만들려면?',
    body: '파티를 게시한 뒤 파티 상세에서 "+ 이벤트 추가"를 눌러요. 체크인은 하단 체크인 탭에서 QR 스캔으로 진행해요.',
  ),
];

class PartyListPage extends ConsumerWidget {
  const PartyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partyListProvider);
    final coordinator = ref.read(partyListCoordinatorProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '파티 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 22,
            tooltip: '도움말',
            onPressed: () => showMinglitHelpSheet(
              context: context,
              title: '파티 관리 가이드',
              sections: _kPartyHelpSections,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: coordinator.goToCreate,
          ),
        ],
      ),
      body: MinglitAsyncValueWidget(
        value: partiesAsync,
        data: (entries) {
          if (entries.isEmpty) {
            return _PartyListEmptyState(onCreateTap: coordinator.goToCreate);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: MinglitSpacing.medium,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
                child: PartyListItem(
                  entry: entry,
                  onTap: () => coordinator.goToDetail(entry.party.id),
                  onNextEventTap: entry.nextEvent != null
                      ? () => coordinator.goToEventDetail(
                          entry.party.id,
                          entry.nextEvent!.id,
                        )
                      : null,
                  onCreateEventTap: () =>
                      coordinator.goToCreateEvent(entry.party.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PartyListEmptyState extends StatelessWidget {
  const _PartyListEmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration_outlined,
              // Fix #2423: size 56 → 64 per spec (party_list_page/index.html:902).
              // MinglitIconSize has no 64px token yet; using xlarge*2 (=64) to match spec.
              size: MinglitIconSize.xlarge * 2,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              context.l10n.partyList_empty_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.xsmall),
            Text(
              context.l10n.partyList_empty_subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.large),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.partyList_empty_createParty),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showMinglitHelpSheet(
                  context: context,
                  title: context.l10n.partyList_helpSheet_title,
                  sections: [
                    HelpSection(
                      leading: const Icon(Icons.celebration_outlined),
                      title: context.l10n.partyList_helpSheet_q1_title,
                      body: context.l10n.partyList_helpSheet_q1_body,
                    ),
                    HelpSection(
                      leading: const Icon(Icons.event_outlined),
                      title: context.l10n.partyList_helpSheet_q2_title,
                      body: context.l10n.partyList_helpSheet_q2_body,
                    ),
                    HelpSection(
                      leading: const Icon(Icons.save_outlined),
                      title: context.l10n.partyList_helpSheet_q3_title,
                      body: context.l10n.partyList_helpSheet_q3_body,
                    ),
                    HelpSection(
                      leading: const Icon(Icons.people_outline),
                      title: context.l10n.partyList_helpSheet_q4_title,
                      body: context.l10n.partyList_helpSheet_q4_body,
                    ),
                  ],
                ),
                icon: const Icon(Icons.help_outline),
                label: Text(context.l10n.partyList_empty_helpButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
