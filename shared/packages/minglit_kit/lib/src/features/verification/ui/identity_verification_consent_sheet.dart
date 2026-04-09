import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_bottom_sheet.dart';

/// Returns whether the user agreed to collect identity verification data.
Future<bool> showIdentityVerificationConsentSheet(BuildContext context) async {
  final result = await showMinglitBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    child: IdentityVerificationConsentSheet(
      onCancel: () => Navigator.of(context).pop(false),
      onAgree: () => Navigator.of(context).pop(true),
    ),
  );

  return result ?? false;
}

/// Consent sheet shown before starting CI/DI identity verification.
class IdentityVerificationConsentSheet extends StatelessWidget {
  /// Creates an [IdentityVerificationConsentSheet].
  const IdentityVerificationConsentSheet({
    required this.onCancel,
    required this.onAgree,
    super.key,
  });

  /// Invoked when the user dismisses the sheet.
  final VoidCallback onCancel;

  /// Invoked when the user agrees and wants to continue.
  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('본인확인정보 수집·이용 동의', style: theme.textTheme.titleLarge),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '본인확인 및 중복가입 방지를 위해 아래 정보를 수집합니다.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: MinglitSpacing.large),
          const _ConsentSection(
            title: '수집 항목',
            items: ['CI', 'DI', '이름', '생년월일', '성별', '휴대폰번호'],
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _ConsentSection(
            title: '수집 목적',
            items: ['본인확인 및 실명 인증', '중복가입 방지'],
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _ConsentSection(title: '보유 기간', items: ['회원 탈퇴 시까지']),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            'CI/DI는 암호화되어 안전하게 저장됩니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAgree,
              child: const Text('동의하고 인증'),
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: onCancel, child: const Text('취소')),
          ),
        ],
      ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: MinglitOpacity.scrimMedium,
        ),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: MinglitSpacing.xsmall),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.xxsmall),
                child: Text('• $item', style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}
