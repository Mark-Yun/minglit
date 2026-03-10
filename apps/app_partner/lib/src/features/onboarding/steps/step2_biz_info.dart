import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step2BizInfo extends ConsumerWidget {
  const Step2BizInfo({super.key});

  /// Gets the localized display text for a bizType value
  String _getBizTypeLabel(BuildContext context, String bizType) {
    return switch (bizType) {
      'individual' => context.l10n.partnerApplication_option_individual,
      'corporate' => context.l10n.partnerApplication_option_corporate,
      _ => bizType,
    };
  }

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
            context.l10n.partnerApplication_field_bizType,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          DropdownButtonFormField<String>(
            initialValue: state.bizType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            hint: Text(_getBizTypeLabel(context, state.bizType)),
            items: [
              DropdownMenuItem(
                value: 'individual',
                child: Text(context.l10n.partnerApplication_option_individual),
              ),
              DropdownMenuItem(
                value: 'corporate',
                child: Text(context.l10n.partnerApplication_option_corporate),
              ),
            ],
            onChanged: (val) {
              if (val != null) notifier.updateField('bizType', val);
            },
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partnerApplication_field_bizName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.bizName,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_bizName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('bizName', val),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partnerApplication_field_bizNumber,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.bizNumber,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_bizNumber,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => notifier.updateField('bizNumber', val),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partnerApplication_field_repName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.representativeName,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_repName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('representativeName', val),
          ),
        ],
      ),
    );
  }
}
