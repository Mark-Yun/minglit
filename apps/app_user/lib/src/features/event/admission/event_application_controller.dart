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

  /// Submits an event application via the unified `apply-event` Edge Function.
  ///
  /// The EF determines whether the ticket is free or paid and responds
  /// accordingly. Free tickets are confirmed immediately; paid tickets
  /// require proceeding through the PG payment flow.
  Future<void> submitApplication(BuildContext context) async {
    if (state.selectedTicket == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(status: EventApplicationStatus.submitting);

    try {
      final repository = ref.read(eventRepositoryProvider);
      final ticket = state.selectedTicket!;
      final event = await _loadEvent();
      final verificationData = _buildVerificationPayload(event, ticket);

      final result = await repository.applyEvent(
        eventId: _event.id,
        ticketId: ticket.id,
        verificationData: verificationData,
      );

      switch (result) {
        case FreeApplyEventResult():
          state = state.copyWith(status: EventApplicationStatus.success);
        case PaidApplyEventResult():
          if (!context.mounted) return;
          await _processPaidApplication(
            context: context,
            repository: repository,
            ticket: ticket,
            user: user,
            result: result,
          );
      }
    } on Object catch (e, st) {
      _handleError(e, st);
    }
  }

  Future<void> _processPaidApplication({
    required BuildContext context,
    required EventRepository repository,
    required Ticket ticket,
    required User user,
    required PaidApplyEventResult result,
  }) async {
    final config = ref.read(iamportConfigProvider);
    final impUid = await ref
        .read(iamportControllerProvider.notifier)
        .startPayment(
          context: context,
          userCode: config.userCode,
          data: {
            'pg': 'html5_inicis',
            'pay_method': 'card',
            'merchant_uid': result.orderId,
            'name': ticket.name,
            'amount': result.paymentAmount,
            'buyer_name': user.userMetadata?['name'] ?? '게스트',
            // Fix #1924: never fabricate a phone number — omit with '' when phone is null.
            // Iamport accepts an empty string; a hardcoded stub causes false PG records.
            'buyer_tel': user.phone ?? '',
            'buyer_email': user.email ?? 'guest@minglit.com',
            'app_scheme': 'minglit',
          },
        );

    if (impUid == null) {
      throw const MinglitUserException('결제가 취소되었습니다.');
    }

    await repository.confirmPayment(
      impUid: impUid,
      merchantUid: result.orderId,
    );

    state = state.copyWith(status: EventApplicationStatus.success);
  }

  void _handleError(Object error, StackTrace st) {
    final exception = MinglitException.from(error, st);
    final message = exception is MinglitSystemException
        ? exception.userMessage
        : exception.message;
    state = state.copyWith(
      status: EventApplicationStatus.error,
      errorMessage: message,
    );
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
