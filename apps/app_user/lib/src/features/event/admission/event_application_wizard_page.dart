import 'dart:async';

import 'package:app_user/src/features/event/admission/event_application_controller.dart';
// Fix #509: payment feature 직접 import 제거 — PaymentSuccessScreen을 admission feature로 이동
import 'package:app_user/src/features/event/admission/payment_success_screen.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

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
      appBar: AppBar(
        title: const Text('참여 신청'),
        leading: const CloseButton(),
      ),
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
                .read(
                  eventApplicationControllerProvider(widget.event).notifier,
                )
                .selectTicket(ticket);
          }),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      eventApplicationControllerProvider(widget.event),
    );
    final controller = ref.read(
      eventApplicationControllerProvider(widget.event).notifier,
    );

    // Listen for success
    ref.listen(
      eventApplicationControllerProvider(widget.event),
      (_, next) {
        if (next.status == EventApplicationStatus.success) {
          final ticket = next.selectedTicket;
          if (ticket == null) return;
          // Fix #453: 콜백으로 coordinator 의존을 wizard 페이지가 소유 — payment → event 순환 제거
          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => PaymentSuccessScreen(
                  event: widget.event,
                  ticketId: ticket.id,
                  onViewTickets: () =>
                      ref.read(eventCoordinatorProvider).goToPurchaseHistory(),
                  onBackToEvent: () => ref
                      .read(eventCoordinatorProvider)
                      .goToEventDetail(widget.event.id),
                ),
              ),
            ),
          );
        }
        if (next.status == EventApplicationStatus.error) {
          unawaited(_handlePaymentError(context, next.errorMessage));
        }
      },
    );

    return Column(
      children: [
        // 1. Progress Indicator
        _StepIndicator(currentStep: state.step),

        // 2. Step Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: state.step == EventApplicationStep.verification
                ? _VerificationStep(event: widget.event)
                : _PaymentStep(event: widget.event),
          ),
        ),

        // 3. Footer Buttons
        _Footer(
          state: state,
          onPrev: controller.previousStep,
          onNext: controller.nextStep,
          onSubmit: () => controller.processPayment(context),
        ),
      ],
    );
  }

  Future<void> _handlePaymentError(
    BuildContext context,
    String? errorMessage,
  ) async {
    final message = errorMessage ?? '결제를 완료하지 못했습니다.';
    final retry = await context.showMinglitConfirm(
      title: '결제 실패',
      message: '$message\n\n다시 시도하시겠어요?',
      confirmLabel: '다시 시도',
      cancelLabel: '닫기',
    );

    if (!mounted) return;
    ref
        .read(eventApplicationControllerProvider(widget.event).notifier)
        .resetStatus();

    if (!context.mounted) return;
    if (retry) {
      unawaited(
        ref
            .read(
              eventApplicationControllerProvider(widget.event).notifier,
            )
            .processPayment(context),
      );
    }
  }
}
