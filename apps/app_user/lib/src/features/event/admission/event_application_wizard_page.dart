import 'dart:async';

import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/logic/event_coordinator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'wizard_consent_step.dart';
part 'wizard_identity_step.dart';
part 'wizard_payment_step.dart';
part 'wizard_verification_step.dart';
part 'wizard_widgets.dart';

class EventApplicationWizardPage extends ConsumerStatefulWidget {
  const EventApplicationWizardPage({
    required this.eventId,
    this.ticketId,
    super.key,
  });

  final String eventId;
  final String? ticketId;

  @override
  ConsumerState<EventApplicationWizardPage> createState() =>
      _EventApplicationWizardPageState();
}

class _EventApplicationWizardPageState
    extends ConsumerState<EventApplicationWizardPage> {
  // Fix #2314: show confirmation dialog on back navigation — wizard state is
  // lost on pop and there is no auto-save, so guard every exit attempt.
  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) return;
    unawaited(_confirmExit());
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('신청을 중단할까요?'),
        content: const Text('지금 나가면 입력한 내용이 모두 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('계속하기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailControllerProvider(widget.eventId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('참여 신청'),
          // Fix #2314: custom onPressed routes through the same confirmation
          // dialog as the Android back gesture, preventing silent state loss.
          leading: CloseButton(onPressed: () => unawaited(_confirmExit())),
        ),
        body: MinglitAsyncValueWidget(
          value: eventAsync,
          data: (event) =>
              _WizardBody(event: event, initialTicketId: widget.ticketId),
        ),
      ),
    );
  }
}

class _WizardBody extends ConsumerStatefulWidget {
  const _WizardBody({required this.event, this.initialTicketId});

  final Event event;
  final String? initialTicketId;

  @override
  ConsumerState<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends ConsumerState<_WizardBody> {
  @override
  void initState() {
    super.initState();
    // Initialize controller with selected ticket if provided
    if (widget.initialTicketId != null) {
      final ticket = widget.event.tickets?.firstWhere(
        (t) => t.id == widget.initialTicketId,
      );
      if (ticket != null) {
        unawaited(
          Future.microtask(() {
            ref
                .read(eventApplicationControllerProvider(widget.event).notifier)
                .selectTicket(ticket);
          }),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventApplicationControllerProvider(widget.event));
    final controller = ref.read(
      eventApplicationControllerProvider(widget.event).notifier,
    );

    // Listen for success
    ref.listen(eventApplicationControllerProvider(widget.event), (_, next) {
      if (next.status == EventApplicationStatus.success) {
        final ticket = next.selectedTicket;
        if (ticket == null) return;
        ref
            .read(eventCoordinatorProvider)
            .replaceWithApplicationConfirmation(
              eventId: widget.event.id,
              ticketId: ticket.id,
            );
      }
      if (next.status == EventApplicationStatus.error) {
        _handlePaymentError(context, next.errorMessage);
      }
    });

    final steps = controller.visibleSteps;

    return Column(
      children: [
        _StepIndicator(steps: steps, currentStep: state.step),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: switch (state.step) {
              EventApplicationStep.identity => _IdentityStep(
                event: widget.event,
              ),
              EventApplicationStep.partnerVerification => _VerificationStep(
                event: widget.event,
              ),
              EventApplicationStep.consent => _ConsentStep(event: widget.event),
              EventApplicationStep.payment => _PaymentStep(event: widget.event),
            },
          ),
        ),

        _Footer(
          state: state,
          steps: steps,
          canMoveNext: controller.canMoveNext,
          onPrev: controller.previousStep,
          onNext: () => controller.nextStep(context),
          onSubmit: () => controller.submitApplication(context),
        ),
      ],
    );
  }

  void _handlePaymentError(BuildContext context, String? errorMessage) {
    final message = errorMessage ?? '결제를 완료하지 못했습니다.';
    context.showMinglitWarning(message);
    ref
        .read(eventApplicationControllerProvider(widget.event).notifier)
        .resetStatus();
  }
}
