import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyVerificationSelector extends StatelessWidget {
  const PartyVerificationSelector({
    required this.verificationsAsync,
    required this.selectedVerificationIds,
    required this.onToggle,
    super.key,
  });

  final AsyncValue<List<Verification>> verificationsAsync;
  final List<String> selectedVerificationIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return verificationsAsync.when(
      data: (verifications) {
        if (verifications.isEmpty) {
          return Text(
            '사용 가능한 인증이 없습니다.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          );
        }
        return ListView.builder(
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
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('인증 목록 로드 실패: $e'),
    );
  }
}
