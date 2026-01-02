import 'dart:async';

import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step1_basic_info.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step2_location.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step3_capacity_contact.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step4_entry_rules.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step5_tickets.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step6_review.dart';
import 'package:app_partner/src/utils/error_handler.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateWizardPage extends ConsumerStatefulWidget {
  const PartyCreateWizardPage({super.key});

  @override
  ConsumerState<PartyCreateWizardPage> createState() =>
      _PartyCreateWizardPageState();
}

class _PartyCreateWizardPageState extends ConsumerState<PartyCreateWizardPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);

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
      ..listen(
        partyCreateWizardControllerProvider.select((s) => s.status),
        (prev, next) {
          next.whenOrNull(
            data: (_) {
              if (prev?.isLoading ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.wizard_review_successMessage),
                  ),
                );
                context.pop(); // Return to Party List
              }
            },
            error: (error, st) {
              handleMinglitError(context, error, st);
            },
          );
        },
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle(context, state.currentStep)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value:
                (state.currentStep.index + 1) / PartyCreateStep.values.length,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView(
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
          if (state.status.isLoading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
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
                    onPressed: state.status.isLoading
                        ? null
                        : notifier.previousStep,
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
                            ? () => unawaited(notifier.submit())
                            : notifier.nextStep),
                  child: Text(
                    state.currentStep == PartyCreateStep.review
                        ? context.l10n.wizard_button_complete
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
