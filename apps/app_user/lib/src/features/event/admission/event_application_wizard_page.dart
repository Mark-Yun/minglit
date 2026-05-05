import 'dart:async';

import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'wizard_consent_step.dart';
part 'wizard_identity_step.dart';
part 'wizard_payment_step.dart';
part 'wizard_verification_step.dart';
part 'wizard_widgets.dart';

class EventApplicationWizardPage extends ConsumerWidget {
  const EventApplicationWizardPage({
    required this.eventId,
    this.ticketId,
    super.key,
  });

  final String eventId;
  final String? ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailControllerProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('참여 신청'), leading: const CloseButton()),
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) => _WizardBody(event: event, initialTicketId: ticketId),
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
