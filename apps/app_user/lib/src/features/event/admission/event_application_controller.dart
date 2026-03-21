import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
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

  Future<void> processPayment(BuildContext context) async {
    if (state.selectedTicket == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(status: EventApplicationStatus.submitting);

    try {
      final repository = ref.read(eventRepositoryProvider);
      final ticket = state.selectedTicket!;
      final event = await _loadEvent();
      final verificationData = _buildVerificationPayload(event, ticket);
      final merchantUid = await _createOrder(
        repository: repository,
        ticket: ticket,
        userId: user.id,
        verificationData: verificationData,
      );

      if (!context.mounted) return;

      final config = ref.read(iamportConfigProvider);
      final impUid = await _requestPayment(
        context: context,
        userCode: config.userCode,
        ticket: ticket,
        user: user,
        merchantUid: merchantUid,
      );

      if (impUid == null) {
        throw const MinglitUserException('결제가 취소되었습니다.');
      }

      await _verifyPayment(
        repository: repository,
        impUid: impUid,
        merchantUid: merchantUid,
      );

      _handlePaymentSuccess();
    } on Object catch (e, st) {
      _handlePaymentFailure(e, st);
    }
  }

  Future<String> _createOrder({
    required EventRepository repository,
    required Ticket ticket,
    required String userId,
    Map<String, dynamic>? verificationData,
  }) async {
    return repository.createOrder(
      eventId: _event.id,
      ticketId: ticket.id,
      userId: userId,
      amount: ticket.price,
      verificationData: verificationData,
    );
  }

  Future<String?> _requestPayment({
    required BuildContext context,
    required String userCode,
    required Ticket ticket,
    required User user,
    required String merchantUid,
  }) async {
    return ref.read(iamportControllerProvider.notifier).startPayment(
      context: context,
      userCode: userCode,
      data: {
        'pg': 'html5_inicis',
        'pay_method': 'card',
        'merchant_uid': merchantUid,
        'name': ticket.name,
        'amount': ticket.price,
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

  Future<void> submitApplication() async {
    if (state.selectedTicket == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(status: EventApplicationStatus.submitting);

    try {
      final repository = ref.read(eventRepositoryProvider);
      final ticket = state.selectedTicket!;
      final event = await _loadEvent();
      final vData = _buildVerificationPayload(event, ticket);

      await repository.applyEvent(
        eventId: _event.id,
        ticketId: ticket.id,
        userId: user.id,
        paymentId: 'MOCK_PAY_${DateTime.now().millisecondsSinceEpoch}',
        paymentAmount: ticket.price,
        verificationData: vData,
      );

      StatsigAnalytics.logEvent(
        MingLitEvent.eventApplied,
        metadata: {'event_id': _event.id},
      );
      state = state.copyWith(status: EventApplicationStatus.success);
    } on Object catch (e) {
      StatsigAnalytics.logEvent(
        MingLitEvent.errorOccurred,
        metadata: {'context': 'event_application', 'event_id': _event.id},
      );
      state = state.copyWith(
        status: EventApplicationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Map<String, dynamic>? _buildVerificationPayload(Event event, Ticket ticket) {
    final entryGroups = event.entryGroups ?? [];
    final reqIds = entryGroups
        .where((g) => ticket.targetEntryGroupIds.contains(g.id))
        .expand((g) => g.requiredVerificationIds)
        .toSet()
        .toList();

    if (reqIds.isEmpty || state.verificationData.isEmpty) return null;
    return {
      'partner_id': event.party?.partnerId,
      'verification_id': reqIds.first,
      'data': state.verificationData,
    };
  }

  Future<Event> _loadEvent() async {
    final cached = ref.read(eventDetailControllerProvider(_event.id)).value;
    if (cached != null) return cached;
    return ref.read(eventRepositoryProvider).getEventById(_event.id);
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
