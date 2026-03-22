import 'package:flutter/widgets.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_application_controller.g.dart';

enum EventApplicationStep {
  verification,
  payment,
}

enum EventApplicationStatus {
  initial,
  submitting,
  success,
  error,
}

class EventApplicationState {
  const EventApplicationState({
    required this.step,
    required this.status,
    this.selectedTicket,
    this.verificationData = const {},
    this.errorMessage,
  });

  final EventApplicationStep step;
  final EventApplicationStatus status;
  final Ticket? selectedTicket;
  final Map<String, dynamic> verificationData;
  final String? errorMessage;

  EventApplicationState copyWith({
    EventApplicationStep? step,
    EventApplicationStatus? status,
    Ticket? selectedTicket,
    Map<String, dynamic>? verificationData,
    String? errorMessage,
  }) {
    return EventApplicationState(
      step: step ?? this.step,
      status: status ?? this.status,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      verificationData: verificationData ?? this.verificationData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@riverpod
class EventApplicationController extends _$EventApplicationController {
  late final Event _event;

  @override
  EventApplicationState build(Event event) {
    _event = event;
    return const EventApplicationState(
      step: EventApplicationStep.verification,
      status: EventApplicationStatus.initial,
    );
  }

  void selectTicket(Ticket ticket) {
    state = state.copyWith(selectedTicket: ticket);
  }

  void updateVerificationData(String key, dynamic value) {
    final newData = Map<String, dynamic>.from(state.verificationData);
    newData[key] = value;
    state = state.copyWith(verificationData: newData);
  }

  void nextStep() {
    if (state.step == EventApplicationStep.verification) {
      state = state.copyWith(step: EventApplicationStep.payment);
    }
  }

  void previousStep() {
    if (state.step == EventApplicationStep.payment) {
      state = state.copyWith(step: EventApplicationStep.verification);
    }
  }

  /// Processes payment for both paid and free events.
  ///
  /// Calls the user-create-order EF for server-side validation. If
  /// [requires_payment] is false (free ticket), skips payment and succeeds
  /// immediately. Otherwise, proceeds with Iamport payment flow.
  Future<void> processPayment(BuildContext context) async {
    if (state.selectedTicket == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(status: EventApplicationStatus.submitting);

    try {
      final repository = ref.read(eventRepositoryProvider);
      final ticket = state.selectedTicket!;

      // Call EF — server validates all business rules (V1~V8)
      final orderResult = await repository.createOrder(
        eventId: _event.id,
        ticketId: ticket.id,
      );

      // V7: price=0 → skip payment, already 'paid' in DB
      if (!orderResult.requiresPayment) {
        _handlePaymentSuccess();
        return;
      }

      if (!context.mounted) return;

      final config = ref.read(iamportConfigProvider);
      final impUid = await _requestPayment(
        context: context,
        userCode: config.userCode,
        ticket: ticket,
        user: user,
        merchantUid: orderResult.applicationId,
        amount: orderResult.amount,
      );

      if (impUid == null) {
        throw const MinglitUserException('결제가 취소되었습니다.');
      }

      await _verifyPayment(
        repository: repository,
        impUid: impUid,
        merchantUid: orderResult.applicationId,
      );

      _handlePaymentSuccess();
    } on Object catch (e, st) {
      _handlePaymentFailure(e, st);
    }
  }

  /// Submits a free event application via the user-create-order EF.
  ///
  /// This method now delegates to [processPayment] which handles both
  /// free and paid flows uniformly through the EF.
  Future<void> submitApplication(BuildContext context) async {
    await processPayment(context);
  }

  Future<String?> _requestPayment({
    required BuildContext context,
    required String userCode,
    required Ticket ticket,
    required User user,
    required String merchantUid,
    required int amount,
  }) async {
    return ref
        .read(iamportControllerProvider.notifier)
        .startPayment(
          context: context,
          userCode: userCode,
          data: {
            'pg': 'html5_inicis',
            'pay_method': 'card',
            'merchant_uid': merchantUid,
            'name': ticket.name,
            'amount': amount,
            'buyer_name': user.userMetadata?['name'] ?? '게스트',
            'buyer_tel': user.phone ?? '01000000000',
            'buyer_email': user.email ?? 'guest@minglit.com',
            'app_scheme': 'minglit',
          },
        );
  }

  Future<void> _verifyPayment({
    required EventRepository repository,
    required String impUid,
    required String merchantUid,
  }) async {
    await repository.confirmPayment(
      impUid: impUid,
      merchantUid: merchantUid,
    );
  }

  void _handlePaymentSuccess() {
    StatsigAnalytics.logEvent(
      MingLitEvent.paymentCompleted,
      metadata: {'event_id': _event.id},
    );
    StatsigAnalytics.logEvent(
      MingLitEvent.eventApplied,
      metadata: {'event_id': _event.id},
    );
    state = state.copyWith(status: EventApplicationStatus.success);
  }

  void _handlePaymentFailure(Object error, StackTrace st) {
    final exception = MinglitException.from(error, st);
    if (exception is MinglitSystemException) {
      StatsigAnalytics.logEvent(
        MingLitEvent.errorOccurred,
        metadata: {'context': 'payment', 'event_id': _event.id},
      );
    } else {
      StatsigAnalytics.logEvent(
        MingLitEvent.paymentFailed,
        metadata: {'event_id': _event.id},
      );
    }
    final message = exception is MinglitSystemException
        ? exception.userMessage
        : exception.message;
    state = state.copyWith(
      status: EventApplicationStatus.error,
      errorMessage: message,
    );
  }

  void resetStatus() {
    state = EventApplicationState(
      step: state.step,
      status: EventApplicationStatus.initial,
      selectedTicket: state.selectedTicket,
      verificationData: state.verificationData,
    );
  }
}
