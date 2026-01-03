import 'package:app_partner/src/features/party/widgets/party_capacity_input.dart';
import 'package:app_partner/src/features/party/widgets/party_contact_input.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Capacity & Contact Form**
///
/// A reusable form component that combines capacity settings and
/// contact methods. Used in both the creation wizard and detail edit screens.
class PartyCapacityContactForm extends StatelessWidget {
  const PartyCapacityContactForm({
    required this.minCount,
    required this.maxCount,
    required this.phoneController,
    required this.emailController,
    required this.kakaoController,
    required this.enabledMethods,
    required this.onMinChanged,
    required this.onMaxChanged,
    required this.onToggleMethod,
    this.onPhoneChanged,
    this.onEmailChanged,
    this.onKakaoChanged,
    this.phoneValidator,
    this.emailValidator,
    super.key,
  });

  final int minCount;
  final int maxCount;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController kakaoController;
  final Set<String> enabledMethods;

  final ValueChanged<int> onMinChanged;
  final ValueChanged<int> onMaxChanged;
  final ValueChanged<String> onToggleMethod;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<String>? onEmailChanged;
  final ValueChanged<String>? onKakaoChanged;

  final String? Function(String?)? phoneValidator;
  final String? Function(String?)? emailValidator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.partyCreate_label_capacity,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        PartyCapacityInput(
          minCount: minCount,
          maxCount: maxCount,
          onMinChanged: onMinChanged,
          onMaxChanged: onMaxChanged,
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text(
          context.l10n.partyCreate_label_contact,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        PartyContactInput(
          phoneController: phoneController,
          emailController: emailController,
          kakaoController: kakaoController,
          enabledMethods: enabledMethods,
          onToggleMethod: onToggleMethod,
          onPhoneChanged: onPhoneChanged,
          onEmailChanged: onEmailChanged,
          onKakaoChanged: onKakaoChanged,
          phoneValidator: phoneValidator,
          emailValidator: emailValidator,
        ),
      ],
    );
  }
}
