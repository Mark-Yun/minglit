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
  @override
  EventApplicationState build(Event event) {
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

      // Map verification data
      Map<String, dynamic>? vData;
      final entryGroups = event.entryGroups ?? [];
      final reqIds = entryGroups
          .where((g) => ticket.targetEntryGroupIds.contains(g.id))
          .expand((g) => g.requiredVerificationIds)
          .toSet()
          .toList();

      if (reqIds.isNotEmpty && state.verificationData.isNotEmpty) {
        vData = {
          'partner_id': event.party?.partnerId,
          'verification_id': reqIds.first,
          'data': state.verificationData,
        };
      }

      // 1. Create Order (Pre-payment)
      final merchantUid = await repository.createOrder(
        eventId: event.id,
        ticketId: ticket.id,
        userId: user.id,
        amount: ticket.price,
        verificationData: vData,
      );

      // 2. Request Payment (Iamport)
      final impUid = await ref
          .read(iamportControllerProvider.notifier)
          .startPayment(
            context: context,
            userCode: 'imp47373200', // TODO: Get from config/env
            data: {
              'merchant_uid': merchantUid,
              'name': ticket.name,
              'amount': ticket.price,
              'buyer_name': user.userMetadata?['name'] ?? 'Guest',
              'buyer_tel': user.phone ?? '01000000000',
              'buyer_email': user.email ?? 'guest@minglit.com',
              'app_scheme': 'minglit', // For iOS redirect
            },
          );

      if (impUid == null) {
        throw Exception('Payment cancelled or failed');
      }

      // 3. Verify Payment (Server)
      await repository.confirmPayment(
        impUid: impUid,
        merchantUid: merchantUid,
      );

      state = state.copyWith(status: EventApplicationStatus.success);
    } on Object catch (e) {
      state = state.copyWith(
        status: EventApplicationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> submitApplication() async {
    if (state.selectedTicket == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(status: EventApplicationStatus.submitting);

    try {
      final repository = ref.read(eventRepositoryProvider);

      Map<String, dynamic>? vData;

      // Map requirements
      final ticket = state.selectedTicket!;
      final entryGroups = event.entryGroups ?? [];
      final reqIds = entryGroups
          .where((g) => ticket.targetEntryGroupIds.contains(g.id))
          .expand((g) => g.requiredVerificationIds)
          .toSet()
          .toList();

      if (reqIds.isNotEmpty && state.verificationData.isNotEmpty) {
        vData = {
          'partner_id': event.party?.partnerId,
          'verification_id': reqIds.first,
          'data': state.verificationData,
        };
      }

      await repository.applyEvent(
        eventId: event.id,
        ticketId: ticket.id,
        userId: user.id,
        paymentId: 'MOCK_PAY_${DateTime.now().millisecondsSinceEpoch}',
        paymentAmount: ticket.price,
        verificationData: vData,
      );

      state = state.copyWith(status: EventApplicationStatus.success);
    } on Object catch (e) {
      state = state.copyWith(
        status: EventApplicationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
