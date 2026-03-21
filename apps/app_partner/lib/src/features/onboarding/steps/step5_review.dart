import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step5Review extends ConsumerWidget {
  const Step5Review({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerApplyControllerProvider);
    final notifier = ref.read(partnerApplyControllerProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: context.l10n.partnerApplication_section_brand,
            onEdit: () => notifier.setStep(0),
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_brandName,
            value: state.brandName,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_intro,
            value: state.introduction,
          ),
          const SizedBox(height: MinglitSpacing.large),
          _SectionHeader(
            title: context.l10n.partnerApplication_section_biz,
            onEdit: () => notifier.setStep(1),
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_bizType,
            value: state.bizType,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_bizName,
            value: state.bizName,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_bizNumber,
            value: state.bizNumber,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_repName,
            value: state.representativeName,
          ),
          const SizedBox(height: MinglitSpacing.large),
          _SectionHeader(
            title: context.l10n.partnerApplication_section_account,
            onEdit: () => notifier.setStep(2),
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_phone,
            value: state.contactPhone,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_email,
            value: state.contactEmail,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_address,
            value: state.address,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_bankName,
            value: state.bankName,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_accountNum,
            value: state.accountNumber,
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_field_holder,
            value: state.accountHolder,
          ),
          _ReviewItem(label: '세금계산서 수신 이메일', value: state.taxEmail),
          const SizedBox(height: MinglitSpacing.large),
          _SectionHeader(
            title: context.l10n.partnerApplication_section_files,
            onEdit: () => notifier.setStep(3),
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_label_bizReg,
            value: state.bizRegistrationFile?.name ??
                state.bizRegistrationPath?.split('/').last ??
                '-',
          ),
          _ReviewItem(
            label: context.l10n.partnerApplication_label_bankbook,
            value: state.bankbookFile?.name ??
                state.bankbookPath?.split('/').last ??
                '-',
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onEdit,
  });

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('수정하기'),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MinglitColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              (value?.isNotEmpty ?? false) ? value! : '-',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
