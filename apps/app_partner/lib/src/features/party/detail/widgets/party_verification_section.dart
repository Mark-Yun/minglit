import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyVerificationSection extends ConsumerWidget {
  const PartyVerificationSection({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(partyVerificationsProvider(partyId));

    return verificationsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(MinglitSpacing.medium),
              child: Text('설정된 참가 자격이 없습니다 (누구나 참여 가능)'),
            ),
          );
        }
        return Column(
          children: [
            ...list.map(
              (v) => VerificationSelectCard(
                verification: v,
                isSelected: false,
                isReadOnly: true,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            AddActionCard(
              title: '참가 자격 수정하기',
              iconData: Icons.edit_outlined,
              onTap: () {
                // TODO(mark): Navigate to Edit Party (Verification Step)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('참가 자격 수정 기능 준비 중입니다.')),
                );
              },
            ),
          ],
        );
      },
      loading: () => const MinglitSkeleton(height: 80),
      error: (e, s) => Text('인증 정보 로드 실패: $e'),
    );
  }
}
