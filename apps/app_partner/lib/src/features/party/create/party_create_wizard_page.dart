import 'dart:async';

import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/steps/step1_basic_info.dart';
import 'package:app_partner/src/features/party/create/steps/step2_location.dart';
import 'package:app_partner/src/features/party/create/steps/step3_capacity_contact.dart';
import 'package:app_partner/src/features/party/create/steps/step4_entry_rules.dart';
import 'package:app_partner/src/features/party/create/steps/step5_tickets.dart';
import 'package:app_partner/src/features/party/create/steps/step6_review.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateWizardPage extends ConsumerStatefulWidget {
  const PartyCreateWizardPage({this.partyId, super.key});

  final String? partyId;

  @override
  ConsumerState<PartyCreateWizardPage> createState() =>
      _PartyCreateWizardPageState();
}

class _PartyCreateWizardPageState extends ConsumerState<PartyCreateWizardPage> {
  late final PageController _pageController;
  bool _didRequestPrefill = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.partyId != null && !_didRequestPrefill) {
      _didRequestPrefill = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref
              .read(partyCreateWizardControllerProvider.notifier)
              .loadForEdit(widget.partyId!),
        );
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepChanged(PartyCreateStep step) {
    unawaited(
      _pageController.animateToPage(
        step.index,
        duration: MinglitAnimation.medium,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);
    ref.read(globalLoadingControllerProvider.notifier).show();
    try {
      await notifier.submit();
    } finally {
      ref.read(globalLoadingControllerProvider.notifier).hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);
    final isEditing = state.editingPartyId != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sync PageController with state
    ref
      ..listen(
        partyCreateWizardControllerProvider.select((s) => s.currentStep),
        (prev, next) {
          if (next.index != _pageController.page?.round()) {
            _onStepChanged(next);
          }
        },
      )
      // Listen to submission status
      ..listen(partyCreateWizardControllerProvider.select((s) => s.status), (
        prev,
        next,
      ) {
        next.whenOrNull(
          data: (_) {
            if (prev?.isLoading ?? false) {
              context
                ..showMinglitSuccess(
                  isEditing
                      ? '파티 정보가 수정되었습니다.'
                      : context.l10n.wizard_review_successMessage,
                )
                ..pop(); // Return to Party List
            }
          },
          error: (error, st) {
            handleMinglitError(context, error, st);
          },
        );
      });

    if (isEditing && !state.isPrefilled) {
      return Scaffold(
        appBar: MinglitTheme.simpleAppBar(
          title: context.l10n.partyDetail_menu_edit,
        ),
        body: const Center(child: MinglitCircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: _getStepTitle(context, state.currentStep),
      ),
      body: Column(
        children: [
          // Styled Progress Indicator
          MinglitLinearProgressIndicator(
            value:
                (state.currentStep.index + 1) / PartyCreateStep.values.length,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                Step1BasicInfo(),
                Step2Location(),
                Step3CapacityContact(),
                Step4EntryRules(),
                Step5Tickets(),
                Step6Review(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              if (state.currentStep.index > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        state.status.isLoading ? null : notifier.previousStep,
                    child: Text(context.l10n.wizard_button_prev),
                  ),
                ),
              if (state.currentStep.index > 0)
                const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.status.isLoading
                      ? null
                      : (state.currentStep == PartyCreateStep.review
                          ? (notifier.validationErrors.isEmpty
                              ? _handleSubmit
                              : null)
                          : notifier.nextStep),
                  child: Text(
                    state.currentStep == PartyCreateStep.review
                        ? (isEditing
                            ? '수정 완료'
                            : context.l10n.wizard_button_complete)
                        : context.l10n.wizard_button_next,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle(BuildContext context, PartyCreateStep step) {
    switch (step) {
      case PartyCreateStep.basicInfo:
        return context.l10n.wizard_step_basic;
      case PartyCreateStep.location:
        return context.l10n.wizard_step_location;
      case PartyCreateStep.capacityAndContact:
        return context.l10n.wizard_step_capacity;
      case PartyCreateStep.entryRules:
        return context.l10n.wizard_step_entry;
      case PartyCreateStep.tickets:
        return context.l10n.wizard_step_ticket;
      case PartyCreateStep.review:
        return context.l10n.wizard_step_review;
    }
  }
}
