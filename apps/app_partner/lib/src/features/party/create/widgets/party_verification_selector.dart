import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyVerificationSelector extends StatelessWidget {
  const PartyVerificationSelector({
    required this.verificationsAsync,
    required this.selectedVerificationIds,
    required this.onToggle,
    required this.onAddTap,
    super.key,
  });

  final AsyncValue<List<Verification>> verificationsAsync;
  final List<String> selectedVerificationIds;
  final void Function(String) onToggle;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return verificationsAsync.when(
      data: (verifications) {
        return Column(
          children: [
            if (verifications.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: verifications.length,
                itemBuilder: (context, index) {
                  final v = verifications[index];
                  final isSelected = selectedVerificationIds.contains(v.id);
                  return VerificationSelectCard(
                    verification: v,
                    isSelected: isSelected,
                    onTap: () => onToggle(v.id),
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.medium,
                ),
                child: Text(
                  '사용 가능한 인증이 없습니다.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),

            // Add Verification Card
            AnimatedContainer(
              duration: MinglitAnimation.fast,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.08), // Light Orange Background
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                // Border is explicitly removed
              ),
              child: InkWell(
                onTap: onAddTap,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                child: Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.medium),
                  child: Row(
                    children: [
                      // Icon Section
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: colorScheme.secondary,
                          size: MinglitIconSize.small,
                        ),
                      ),
                      const SizedBox(width: MinglitSpacing.medium),

                      // Text Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '새로운 인증 만들기',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: MinglitSpacing.xxsmall),
                            Text(
                              '원하는 참가 자격이 없다면 직접 만들어보세요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: MinglitSpacing.small),

                      // Right Indicator
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.secondary.withValues(alpha: 0.6),
                        size: MinglitIconSize.large,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('인증 목록 로드 실패: $e'),
    );
  }
}
