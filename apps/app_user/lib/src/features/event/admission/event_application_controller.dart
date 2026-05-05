import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_application_controller.g.dart';

const _noChange = Object();

enum EventApplicationStep { identity, partnerVerification, consent, payment }

enum EventApplicationStatus { initial, submitting, success, error }

class EventApplicationState {
  const EventApplicationState({
    required this.step,
    required this.status,
    required this.identityCompleted,
    required this.partnerVerifications,
    required this.consentGranted,
    this.consentCheckedItems = const [],
    this.selectedTicket,
    this.verificationData = const {},
    this.errorMessage,
  });

  final EventApplicationStep step;
  final EventApplicationStatus status;
  final bool identityCompleted;
  final List<PartnerVerifEntry> partnerVerifications;
  final bool consentGranted;

  /// Per-item checked state for the consent checkboxes.
  /// Length matches the number of consent items in the UI.
  final List<bool> consentCheckedItems;

  final Ticket? selectedTicket;
  final Map<String, Map<String, dynamic>> verificationData;
  final String? errorMessage;

  EventApplicationState copyWith({
    EventApplicationStep? step,
    EventApplicationStatus? status,
    bool? identityCompleted,
    List<PartnerVerifEntry>? partnerVerifications,
    bool? consentGranted,
    List<bool>? consentCheckedItems,
    Ticket? selectedTicket,
    Map<String, Map<String, dynamic>>? verificationData,
    Object? errorMessage = _noChange,
  }) {
    return EventApplicationState(
      step: step ?? this.step,
      status: status ?? this.status,
      identityCompleted: identityCompleted ?? this.identityCompleted,
      partnerVerifications: partnerVerifications ?? this.partnerVerifications,
      consentGranted: consentGranted ?? this.consentGranted,
      consentCheckedItems: consentCheckedItems ?? this.consentCheckedItems,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      verificationData: verificationData ?? this.verificationData,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class PartnerVerifEntry {
  const PartnerVerifEntry({
    required this.verification,
    this.status,
    this.prefill = const {},
    this.rejectionReason,
    this.isApproved = false,
  });

  final Verification verification;
  final VerificationStatus? status;
  final Map<String, dynamic> prefill;
  final String? rejectionReason;
  final bool isApproved;

  bool get isRejected => status == VerificationStatus.rejected && !isApproved;
}

@riverpod
class EventApplicationController extends _$EventApplicationController {
  late final Event _event;

  @override
  EventApplicationState build(Event event) {
    _event = event;
    final identityCompleted =
        ref.read(currentUserProfileProvider).value?.isVerified ?? false;
    return EventApplicationState(
      step: EventApplicationStep.identity,
      status: EventApplicationStatus.initial,
      identityCompleted: identityCompleted,
      partnerVerifications: const [],
      consentGranted: false,
      consentCheckedItems: const [],
    );
  }

  List<EventApplicationStep> get visibleSteps {
    final steps = <EventApplicationStep>[
      EventApplicationStep.identity,
      if (shouldShowPartnerVerificationStep)
        EventApplicationStep.partnerVerification,
      EventApplicationStep.consent,
      EventApplicationStep.payment,
    ];
    return steps;
  }

  bool get shouldShowPartnerVerificationStep {
    final entries = state.partnerVerifications;
    if (entries.isEmpty) return false;
    return entries.any((entry) => !entry.isApproved);
  }

  Future<void> selectTicket(Ticket ticket) async {
    state = state.copyWith(selectedTicket: ticket);
    await _loadPartnerVerifications(ticket);
  }

  void markIdentityCompleted() {
    state = state.copyWith(identityCompleted: true);
  }

  void setConsentGranted(bool value) {
    state = state.copyWith(consentGranted: value);
  }

  /// Initialises [consentCheckedItems] with [count] unchecked items.
  /// Called by the consent step on first mount with the number of consent items.
  void initConsentItems(int count) {
    if (state.consentCheckedItems.length == count) return;
    final allGranted = state.consentGranted;
    state = state.copyWith(
      consentCheckedItems: List.filled(count, allGranted),
    );
  }

  /// Toggles the checked state of the consent item at [index] and updates
  /// [consentGranted] based on whether all items are now checked.
  void toggleConsentItem(int index, bool value) {
    final next = List<bool>.from(state.consentCheckedItems)..[index] = value;
    state = state.copyWith(
      consentCheckedItems: next,
      consentGranted: next.every((item) => item),
    );
  }

  void updateVerificationData(
    String verificationId,
    String fieldKey,
    dynamic value,
  ) {
    final newData = Map<String, Map<String, dynamic>>.from(
      state.verificationData,
    );
    final fields = Map<String, dynamic>.from(
      newData[verificationId] ?? const {},
    );
    fields[fieldKey] = value;
    newData[verificationId] = fields;
    state = state.copyWith(verificationData: newData);
  }

  void setPartnerVerifications(List<PartnerVerifEntry> entries) {
    final mergedData = Map<String, Map<String, dynamic>>.from(
      state.verificationData,
    );
    for (final entry in entries) {
      if (!mergedData.containsKey(entry.verification.id) ||
          mergedData[entry.verification.id]!.isEmpty) {
        mergedData[entry.verification.id] = Map<String, dynamic>.from(
          entry.prefill,
        );
      }
    }
    state = state.copyWith(
      partnerVerifications: entries,
      verificationData: mergedData,
    );
  }

  Future<void> nextStep(BuildContext context) async {
    if (!_canMoveNext(context)) return;
    final steps = visibleSteps;
    final currentIndex = steps.indexOf(state.step);
    if (currentIndex == -1 || currentIndex >= steps.length - 1) return;
    state = state.copyWith(step: steps[currentIndex + 1], errorMessage: null);
  }

  void previousStep() {
    final steps = visibleSteps;
    final currentIndex = steps.indexOf(state.step);
    if (currentIndex <= 0) return;
    state = state.copyWith(step: steps[currentIndex - 1]);
  }

  bool get canMoveNext {
    return switch (state.step) {
      EventApplicationStep.identity => state.identityCompleted,
      EventApplicationStep.partnerVerification => true,
      EventApplicationStep.consent => state.consentGranted,
      EventApplicationStep.payment => false,
    };
  }

  bool _canMoveNext(BuildContext context) {
    if (state.step == EventApplicationStep.partnerVerification &&
        !_hasCompletedRequiredVerificationFields()) {
      context.showMinglitWarning('필수 인증 항목을 모두 입력해주세요');
      return false;
    }
    return canMoveNext;
  }

  bool _hasCompletedRequiredVerificationFields() {
    for (final entry in state.partnerVerifications) {
      if (entry.isApproved) continue;
      final data =
          state.verificationData[entry.verification.id] ?? entry.prefill;
      for (final field in entry.verification.formSchema) {
        if (!field.required) continue;
        final value = data[field.key];
        if (value == null) return false;
        if (value is String && value.trim().isEmpty) return false;
        if (value is Iterable && value.isEmpty) return false;
      }
    }
    return true;
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
            // Fix #1924: empty string avoids fake phone numbers in PG records
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
    final reqIds = _requiredVerificationIdsFor(ticket, event);
    if (reqIds.isEmpty || state.verificationData.isEmpty) return null;
    final verifications = state.verificationData.entries
        .where((e) => reqIds.contains(e.key) && e.value.isNotEmpty)
        .map((e) => {'verification_id': e.key, 'data': e.value})
        .toList();
    if (verifications.isEmpty) return null;
    return {
      'partner_id': event.party?.partnerId,
      'verifications': verifications,
    };
  }

  Future<void> _loadPartnerVerifications(Ticket ticket) async {
    final partnerId = _event.party?.partnerId;
    final requiredIds = _requiredVerificationIdsFor(ticket, _event);
    if (partnerId == null || requiredIds.isEmpty) {
      state = state.copyWith(
        partnerVerifications: const [],
        verificationData: const {},
      );
      return;
    }

    try {
      final statuses = await ref
          .read(verificationRepositoryProvider)
          .getPartnerRequirementsStatus(
            partnerId: partnerId,
            requiredVerificationIds: requiredIds,
          );
      final entries =
          statuses
              .map(
                (status) => PartnerVerifEntry(
                  verification: status.master,
                  status: status.status,
                  prefill: _extractPrefill(status),
                  rejectionReason: _extractRejectionReason(status),
                  isApproved: status.isApproved,
                ),
              )
              .toList()
            ..sort(
              (a, b) => requiredIds
                  .indexOf(a.verification.id)
                  .compareTo(requiredIds.indexOf(b.verification.id)),
            );
      setPartnerVerifications(entries);
    } on Object catch (error, stackTrace) {
      Log.e('Failed to load partner verifications', error, stackTrace);
      state = state.copyWith(
        partnerVerifications: const [],
        verificationData: const {},
      );
    }
  }

  List<String> _requiredVerificationIdsFor(Ticket ticket, Event event) {
    final entryGroups = event.entryGroups ?? [];
    return entryGroups
        .where((group) => ticket.targetEntryGroupIds.contains(group.id))
        .expand((group) => group.requiredVerificationIds)
        .toSet()
        .toList();
  }

  Map<String, dynamic> _extractPrefill(VerificationRequirementStatus status) {
    final userVerification = status.userVerification;
    final fromUserVerification =
        _extractMap(userVerification?['data']) ??
        _extractMap(userVerification?['claim_data']);
    if (fromUserVerification != null) {
      return fromUserVerification;
    }

    final verifiedData =
        _extractMap(status.verifiedResult?['data']) ??
        _extractMap(status.verifiedResult?['claim_data']);
    if (verifiedData != null) {
      return verifiedData;
    }

    final activeSubmission = status.activeSubmission;
    if (activeSubmission == null) return const {};
    final snapshotPrefill = <String, dynamic>{};
    for (final item in activeSubmission.snapshotData) {
      if (item is! Map<String, dynamic>) continue;
      final key =
          item['key'] ?? item['field_key'] ?? item['name'] ?? item['label'];
      final value = item['value'] ?? item['answer'] ?? item['data'];
      if (key is String && value != null) {
        snapshotPrefill[key] = value;
      }
    }
    return snapshotPrefill;
  }

  String? _extractRejectionReason(VerificationRequirementStatus status) {
    final verifiedResult = status.verifiedResult;
    final rejectionReason = verifiedResult?['rejection_reason'];
    if (rejectionReason is String && rejectionReason.isNotEmpty) {
      return rejectionReason;
    }
    return null;
  }

  Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  Future<Event> _loadEvent() async {
    final cached = ref.read(eventDetailControllerProvider(_event.id)).value;
    if (cached != null) return cached;
    return ref.read(eventRepositoryProvider).getEventById(_event.id);
  }

  void resetStatus() {
    state = state.copyWith(
      status: EventApplicationStatus.initial,
      errorMessage: null,
    );
  }
}
