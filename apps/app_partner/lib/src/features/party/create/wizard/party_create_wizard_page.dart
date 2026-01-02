import 'dart:async';

import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step1_basic_info.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step2_location.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step3_capacity_contact.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step4_entry_rules.dart';
import 'package:app_partner/src/features/party/create/wizard/steps/step5_tickets.dart';
import 'package:flutter/material.dart';
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

    // Sync PageController with state if needed
    ref.listen(
      partyCreateWizardControllerProvider.select((s) => s.currentStep),
      (prev, next) {
        if (next.index != _pageController.page?.round()) {
          _onStepChanged(next);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle(state.currentStep)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value:
                (state.currentStep.index + 1) / PartyCreateStep.values.length,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          Step1BasicInfo(),
          Step2Location(),
          Step3CapacityContact(),
          Step4EntryRules(),
          Step5Tickets(),
          Center(
            child: Text('Review & Submit'),
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
                    onPressed: notifier.previousStep,
                    child: const Text('이전'),
                  ),
                ),
              if (state.currentStep.index > 0)
                const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: state.currentStep == PartyCreateStep.review
                      ? () => unawaited(notifier.submit())
                      : notifier.nextStep,
                  child: Text(
                    state.currentStep == PartyCreateStep.review
                        ? '기획 완료'
                        : '다음',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle(PartyCreateStep step) {
    switch (step) {
      case PartyCreateStep.basicInfo:
        return '1. 기본 정보';
      case PartyCreateStep.location:
        return '2. 장소 설정';
      case PartyCreateStep.capacityAndContact:
        return '3. 인원 및 연락처';
      case PartyCreateStep.entryRules:
        return '4. 입장 규칙';
      case PartyCreateStep.tickets:
        return '5. 티켓 설정';
      case PartyCreateStep.review:
        return '최종 확인';
    }
  }
}
