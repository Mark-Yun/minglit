import 'dart:async';

import 'package:app_partner/src/features/onboarding/onboarding_coordinator.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/steps/step1_basic_info.dart';
import 'package:app_partner/src/features/onboarding/steps/step2_biz_info.dart';
import 'package:app_partner/src/features/onboarding/steps/step3_contact_settlement.dart';
import 'package:app_partner/src/features/onboarding/steps/step4_documents.dart';
import 'package:app_partner/src/features/onboarding/steps/step5_review.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerApplyPage extends ConsumerStatefulWidget {
  const PartnerApplyPage({super.key});

  @override
  ConsumerState<PartnerApplyPage> createState() => _PartnerApplyPageState();
}

class _PartnerApplyPageState extends ConsumerState<PartnerApplyPage> {
  late final PageController _pageController;
  // Fix #2130: flag to suppress animateToPage during draft restore — prevents
  // title/content desync where AppBar shows the restored step title but the
  // PageView is still animating from page 0 through intermediate steps.
  bool _isRestoringDraft = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreDraft());
    });
  }

  Future<void> _restoreDraft() async {
    _isRestoringDraft = true;
    try {
      await ref.read(partnerApplyControllerProvider.notifier).loadDraft();
    } finally {
      _isRestoringDraft = false;
    }
    if (!mounted) return;
    final step = ref.read(partnerApplyControllerProvider).currentStep;
    if (step > 0 && _pageController.hasClients) {
      // Fix #2130: jumpToPage (instant) avoids animation-period desync
      _pageController.jumpToPage(step);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged(int step) {
    // Fix #2130: skip animated transition during draft restore
    if (_isRestoringDraft) return;
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
            // Fix #404: Use coordinator instead of direct GoRouter access
            if (prev?.isLoading ?? false) {
              ref.read(onboardingCoordinatorProvider).goToApplyStatus();
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
            itemBuilder: (context) => [
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
                  // Fix #2162, #2163: validate current step before advancing —
                  // nextStep() had no validation gate, allowing progression
                  // through Step 3/4 without required fields
                  onPressed: isLoading
                      ? null
                      : (isLastStep
                            ? (notifier.canProceed() ? notifier.submit : null)
                            : (notifier.validateStep(state.currentStep)
                                ? notifier.nextStep
                                : null)),
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
    unawaited(
      MinglitAlert.showConfirm(
        context: context,
        title: context.l10n.home_button_logout,
        content: '로그아웃 하시겠습니까?',
        confirmText: context.l10n.home_button_logout,
        cancelText: context.l10n.common_button_cancel,
      ).then((confirmed) async {
        if (!confirmed) return;
        // Fix: showConfirm closes dialog before resolving, so signOut's
        // GoRouter redirect won't hit an invalidated context.
        final authRepo = ref.read(authRepositoryProvider);
        await Future<void>.delayed(Duration.zero);
        await authRepo.signOut();
      }),
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
