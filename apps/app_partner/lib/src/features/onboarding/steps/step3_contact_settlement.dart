import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step3ContactSettlement extends ConsumerWidget {
  const Step3ContactSettlement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerApplyControllerProvider);
    final notifier = ref.read(partnerApplyControllerProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.partnerApplication_field_phone,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.contactPhone,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_phone,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (val) => notifier.updateField('contactPhone', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_email,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.contactEmail,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => notifier.updateField('contactEmail', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_address,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.address,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_address,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('address', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_bankName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.bankName,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_bankName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('bankName', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_accountNum,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.accountNumber,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_accountNum,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => notifier.updateField('accountNumber', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            context.l10n.partnerApplication_field_holder,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.accountHolder,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_field_holder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('accountHolder', val),
          ),
          const SizedBox(height: MinglitSpacing.large),

          Text(
            '세금계산서 수신 이메일',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.taxEmail,
            decoration: InputDecoration(
              hintText: '이메일 주소를 입력해주세요 (선택)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => notifier.updateField('taxEmail', val),
          ),
        ],
      ),
    );
  }
}
