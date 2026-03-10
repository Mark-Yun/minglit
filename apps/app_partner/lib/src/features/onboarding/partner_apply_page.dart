import 'dart:async';

import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/steps/step1_basic_info.dart';
import 'package:app_partner/src/features/onboarding/steps/step2_biz_info.dart';
import 'package:app_partner/src/features/onboarding/steps/step3_contact_settlement.dart';
import 'package:app_partner/src/features/onboarding/steps/step4_documents.dart';
import 'package:app_partner/src/features/onboarding/steps/step5_review.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerApplyPage extends ConsumerStatefulWidget {
  const PartnerApplyPage({super.key});

  @override
  ConsumerState<PartnerApplyPage> createState() => _PartnerApplyPageState();
}

class _PartnerApplyPageState extends ConsumerState<PartnerApplyPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(partnerApplyControllerProvider.notifier).loadDraft());
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged(int step) {
    if (_pageController.hasClients) {
      unawaited(
        _pageController.animateToPage(
          step,
          duration: MinglitAnimation.medium,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerApplyControllerProvider);
    final notifier = ref.read(partnerApplyControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const totalSteps = 5;

    // Sync PageController with state
    ref
      ..listen(partnerApplyControllerProvider.select((s) => s.currentStep), (
        prev,
        next,
      ) {
        if (prev != next) {
          _onStepChanged(next);
        }
      })
      // Listen to submission status
      ..listen(partnerApplyControllerProvider.select((s) => s.status), (
        prev,
        next,
      ) {
        next.whenOrNull(
          data: (_) {
            if (prev?.isLoading ?? false) {
              context.go('/apply/status');
            }
          },
          error: (error, st) {
            handleMinglitError(context, error, st);
          },
        );
      });

    final isLastStep = state.currentStep == totalSteps - 1;
    final isLoading = state.isSaving || state.isSubmitting;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: _getStepTitle(context, state.currentStep),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(context.l10n.home_button_logout),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              MinglitLinearProgressIndicator(
                value: (state.currentStep + 1) / totalSteps,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: MinglitColors.primary,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Step1BasicInfo(),
                    Step2BizInfo(),
                    Step3ContactSettlement(),
                    Step4Documents(),
                    Step5Review(),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: MinglitColors.scrim,
                child: Center(child: MinglitCircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Row(
            children: [
              if (state.currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : notifier.previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: MinglitSpacing.medium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          MinglitRadius.button,
                        ),
                      ),
                    ),
                    child: Text(context.l10n.partnerApplication_wizard_prev),
                  ),
                ),
              if (state.currentStep > 0)
                const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : (isLastStep
                            ? (notifier.canProceed() ? notifier.submit : null)
                            : notifier.nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MinglitColors.primary,
                    foregroundColor: MinglitColors.background,
                    padding: const EdgeInsets.symmetric(
                      vertical: MinglitSpacing.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MinglitRadius.button),
                    ),
                  ),
                  child: Text(
                    isLastStep
                        ? context.l10n.partnerApplication_wizard_submit
                        : context.l10n.partnerApplication_wizard_next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.home_button_logout),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.common_button_cancel),
            ),
            TextButton(
              onPressed: () async {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(context.l10n.home_button_logout),
            ),
          ],
        );
      },
    );
  }

  String _getStepTitle(BuildContext context, int step) {
    return switch (step) {
      0 => context.l10n.partnerApplication_wizard_step1_title,
      1 => context.l10n.partnerApplication_wizard_step2_title,
      2 => context.l10n.partnerApplication_wizard_step3_title,
      3 => context.l10n.partnerApplication_wizard_step4_title,
      4 => context.l10n.partnerApplication_wizard_step5_title,
      _ => context.l10n.partnerApplication_wizard_title,
    };
  }
}
