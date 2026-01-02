import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/wizard/party_entry_group_editor_screen.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_basic_condition_section.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step4EntryRules extends ConsumerWidget {
  const Step4EntryRules({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '누가 파티에 입장할 수 있나요?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: MinglitSpacing.small),
          const Text(
            '성별, 나이, 필수 인증을 조합하여 입장 그룹을 만들어보세요.\n'
            '(예: "20대 남성 + 재직증명", "20대 여성 + 학생증")',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // List of Entry Groups
          if (state.entryGroups.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.entryGroups.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: MinglitSpacing.medium),
              itemBuilder: (context, index) {
                final group = state.entryGroups[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MinglitSpacing.medium,
                          vertical: MinglitSpacing.small,
                        ),
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '입장 그룹 ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () => notifier.removeEntryGroup(group.id),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Theme(
                        data: theme.copyWith(
                          cardTheme: const CardThemeData(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            color: Colors.transparent,
                          ),
                        ),
                        child: PartyBasicConditionSection(
                          party: Party(
                            id: '',
                            partnerId: '',
                            title: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            conditions: [group.toJson()],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Add Button
          AddActionCard(
            title: '입장 그룹 추가하기',
            subtitle: '새로운 입장 조건을 설정합니다.',
            onTap: () => _showEntryGroupEditor(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text('아직 추가된 입장 그룹이 없습니다.'),
      ),
    );
  }

  Future<void> _showEntryGroupEditor(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PartyEntryGroupEditorScreen(),
      ),
    );
  }
}
