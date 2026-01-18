import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/matching/matching_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MatchingSettingsScreen extends ConsumerStatefulWidget {
  const MatchingSettingsScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<MatchingSettingsScreen> createState() =>
      _MatchingSettingsScreenState();
}

class _MatchingSettingsScreenState
    extends ConsumerState<MatchingSettingsScreen> {
  // Map<SourceGroupId, Set<TargetGroupId>>
  final Map<String, Set<String>> _selectedRules = {};
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final rulesAsync = ref.watch(eventMatchRulesProvider(widget.eventId));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '매칭 규칙 설정',
      ),
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) {
          return MinglitAsyncValueWidget(
            value: rulesAsync,
            data: (existingRules) {
              if (!_isInitialized) {
                _initializeRules(existingRules);
                _isInitialized = true;
              }
              return _buildContent(event);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _initializeRules(List<MatchRule> rules) {
    for (final rule in rules) {
      _selectedRules.putIfAbsent(rule.sourceGroupId, () => {}).add(
            rule.targetGroupId,
          );
    }
  }

  Widget _buildContent(Event event) {
    final groups = event.entryGroups ?? [];
    if (groups.length < 2) {
      return const Center(
        child: Text('매칭을 설정하려면 최소 2개의 입장 그룹이 필요합니다.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      itemCount: groups.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: MinglitSpacing.large),
      itemBuilder: (context, index) {
        final sourceGroup = groups[index];
        return _buildGroupRuleCard(sourceGroup, groups);
      },
    );
  }

  Widget _buildGroupRuleCard(
    EntryGroup sourceGroup,
    List<EntryGroup> allGroups,
  ) {
    final theme = Theme.of(context);
    final selectedTargets =
        _selectedRules[sourceGroup.id] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${sourceGroup.label ?? "그룹 ${sourceGroup.id}"} 참가자는...',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '아래 그룹을 지목할 수 있습니다:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Wrap(
              spacing: MinglitSpacing.small,
              runSpacing: MinglitSpacing.small,
              children: allGroups
                  .where((g) => g.id != sourceGroup.id)
                  .map((targetGroup) {
                final isSelected = selectedTargets.contains(targetGroup.id);
                return FilterChip(
                  label: Text(targetGroup.label ?? '그룹'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRules
                            .putIfAbsent(sourceGroup.id, () => {})
                            .add(targetGroup.id);
                      } else {
                        _selectedRules[sourceGroup.id]?.remove(targetGroup.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _handleSave,
          child: const Text('저장하기'),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final rules = <Map<String, String>>[];
    _selectedRules.forEach((source, targets) {
      for (final target in targets) {
        rules.add({
          'source_group_id': source,
          'target_group_id': target,
        });
      }
    });

    await ref.read(matchingControllerProvider.notifier).updateRules(
          eventId: widget.eventId,
          rules: rules,
        );

    final state = ref.read(matchingControllerProvider);
    if (!state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('매칭 규칙이 저장되었습니다.')),
      );
      ref.invalidate(eventMatchRulesProvider(widget.eventId));
    } else if (state.hasError && mounted) {
      handleMinglitError(context, state.error!, state.stackTrace);
    }
  }
}
