import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_admission_controller.g.dart';

enum EventAdmissionStatus {
  guest, // 로그인 필요
  identityRequired, // 본인인증 필요 (기본 신뢰)
  qualificationRequired, // 자격 심사 필요 (직장, 학력 등)
  notEligible, // 나이/성별 조건 미달 (이 이벤트의 모든 티켓에 대해)
  eligible, // 조건 만족 (티켓 구매 가능)
  pendingPayment, // 결제 미완료 (이어하기)
  applied, // 이미 신청함/참여중 (결제 완료/심사 대기/승인)
  rejected, // 심사 거절됨 (재신청 가능하도록 유도)
}

/// **Admission State**
///
/// Holds the calculated status and detailed reasons.
class AdmissionState {
  AdmissionState({
    required this.status,
    this.user,
    this.ineligibleReason,
    this.rejectionReason,
    this.missingVerificationIds = const [],
  });

  final EventAdmissionStatus status;
  final User? user;
  final String? ineligibleReason;
  final String? rejectionReason;
  final List<String> missingVerificationIds;
}

@riverpod
class EventAdmissionController extends _$EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    final currentUser = ref.watch(currentUserProvider);
    final repository = ref.watch(eventRepositoryProvider);
    final userRepository = ref.watch(userRepositoryProvider);

    // 1. Check Login
    if (currentUser == null) {
      return AdmissionState(status: EventAdmissionStatus.guest);
    }

    // 2. Check Existing Application (DB Check)
    final existingApp = await repository.getApplication(
      eventId: event.id,
      userId: currentUser.id,
    );

    if (existingApp != null) {
      if (existingApp.status == 'pending') {
        return AdmissionState(
          status: EventAdmissionStatus.pendingPayment,
          user: currentUser,
        );
      }
      if (existingApp.status == 'rejected') {
        return AdmissionState(
          status: EventAdmissionStatus.rejected,
          user: currentUser,
          rejectionReason: existingApp.rejectionReason,
        );
      }
      if (existingApp.status != 'cancelled') {
        return AdmissionState(
          status: EventAdmissionStatus.applied,
          user: currentUser,
        );
      }
    }

    // 3. Fetch User Profile (Identity Check)
    final userProfile = await userRepository.getUserProfile(currentUser.id);

    if (userProfile == null || !userProfile.isVerified) {
      return AdmissionState(
        status: EventAdmissionStatus.identityRequired,
        user: currentUser,
      );
    }

    // 4. Fetch User's Approved Verifications
    final userVerifIds = await userRepository.getApprovedVerificationIds(
      currentUser.id,
    );

    // 5. Check Eligibility & Qualifications
    final tickets = event.tickets ?? [];
    final entryGroups = event.entryGroups ?? [];

    if (tickets.isEmpty) {
      return AdmissionState(
        status: EventAdmissionStatus.eligible,
        user: currentUser,
      );
    }

    var isAnyEligible = false;
    var isAnyQualificationNeeded = false;
    String? firstIneligibleReason;
    final allMissingIds = <String>{};

    for (final ticket in tickets) {
      final groups = entryGroups
          .where((g) => ticket.targetEntryGroupIds.contains(g.id))
          .toList();

      if (groups.isEmpty) {
        isAnyEligible = true;
        break;
      }

      for (final group in groups) {
        // A. Basic Condition Check (Age/Gender)
        final reason = _checkGroupCondition(group, userProfile);
        if (reason == null) {
          // B. Qualification Check
          final missingIds = group.requiredVerificationIds
              .where((id) => !userVerifIds.contains(id))
              .toList();

          if (missingIds.isEmpty) {
            isAnyEligible = true;
            break;
          } else {
            isAnyQualificationNeeded = true;
            allMissingIds.addAll(missingIds);
          }
        } else {
          firstIneligibleReason ??= reason;
        }
      }
      if (isAnyEligible) break;
    }

    if (isAnyEligible) {
      return AdmissionState(
        status: EventAdmissionStatus.eligible,
        user: currentUser,
      );
    }

    if (isAnyQualificationNeeded) {
      return AdmissionState(
        status: EventAdmissionStatus.qualificationRequired,
        user: currentUser,
        missingVerificationIds: allMissingIds.toList(),
      );
    }

    return AdmissionState(
      status: EventAdmissionStatus.notEligible,
      user: currentUser,
      ineligibleReason: firstIneligibleReason ?? '참여 조건이 맞지 않습니다.',
    );
  }

  /// Returns reason if NOT eligible, null if eligible.
  String? _checkGroupCondition(EntryGroup group, UserProfile user) {
    // 1. Gender Check
    if (group.gender != null) {
      // group.gender is 'male'/'female'. user.gender is 'male'/'female'.
      if (group.gender != user.gender) {
        return '성별 조건이 맞지 않습니다.';
      }
    }

    // 2. Age Check
    if (user.birthDate == null) return '생년월일 정보가 없습니다.';

    final birthYear = user.birthDate!.year;
    if (group.birthYearMin != null && birthYear < group.birthYearMin!) {
      return '${group.birthYearMin}년생 이상만 참여 가능합니다.';
    }
    if (group.birthYearMax != null && birthYear > group.birthYearMax!) {
      return '${group.birthYearMax}년생 이하만 참여 가능합니다.';
    }

    return null; // OK
  }
}

class TicketRecommendationResult {
  const TicketRecommendationResult({
    required this.recommendedTicket,
    required this.eligibleTickets,
    required this.ineligibleReasons,
  });

  final Ticket? recommendedTicket;
  final List<Ticket> eligibleTickets;
  final Map<String, String> ineligibleReasons;
}

class TicketRecommendationUtil {
  static TicketRecommendationResult recommend({
    required Event event,
    required UserProfile? userProfile,
    required List<String> approvedVerificationIds,
    required Map<String, bool> balanceStatus,
  }) {
    final tickets = event.tickets ?? [];
    final entryGroups = event.entryGroups ?? [];
    final ineligibleReasons = <String, String>{};
    final eligibleTickets = <Ticket>[];

    for (final ticket in tickets) {
      final evaluation = _evaluateTicket(
        ticket: ticket,
        entryGroups: entryGroups,
        userProfile: userProfile,
        approvedVerificationIds: approvedVerificationIds,
        balanceStatus: balanceStatus,
      );

      if (evaluation.isEligible) {
        eligibleTickets.add(ticket);
      } else if (evaluation.reason != null) {
        ineligibleReasons[ticket.id] = evaluation.reason!;
      }
    }

    eligibleTickets.sort((a, b) {
      final priceCompare = a.price.compareTo(b.price);
      if (priceCompare != 0) return priceCompare;
      return a.name.compareTo(b.name);
    });

    return TicketRecommendationResult(
      recommendedTicket: eligibleTickets.isEmpty ? null : eligibleTickets.first,
      eligibleTickets: eligibleTickets,
      ineligibleReasons: ineligibleReasons,
    );
  }

  static _TicketEligibility _evaluateTicket({
    required Ticket ticket,
    required List<EntryGroup> entryGroups,
    required UserProfile? userProfile,
    required List<String> approvedVerificationIds,
    required Map<String, bool> balanceStatus,
  }) {
    if (balanceStatus[ticket.id] == false) {
      return const _TicketEligibility.ineligible('성비 조절 중');
    }

    if (userProfile == null) {
      return const _TicketEligibility.ineligible('회원 정보가 없습니다.');
    }

    if (!userProfile.isVerified) {
      return const _TicketEligibility.ineligible('본인 인증이 필요합니다.');
    }

    final groups = entryGroups
        .where((group) => ticket.targetEntryGroupIds.contains(group.id))
        .toList();

    if (groups.isEmpty) {
      final missing = _missingVerificationIds(
        ticket.requiredVerificationIds,
        approvedVerificationIds,
      );
      if (missing.isNotEmpty) {
        return const _TicketEligibility.ineligible('필수 인증이 필요합니다.');
      }
      return const _TicketEligibility.eligible();
    }

    String? firstReason;
    for (final group in groups) {
      final reason = _checkGroupCondition(group, userProfile);
      if (reason != null) {
        firstReason ??= reason;
        continue;
      }

      final requiredIds = <String>{
        ...ticket.requiredVerificationIds,
        ...group.requiredVerificationIds,
      };
      final missing = _missingVerificationIds(
        requiredIds.toList(),
        approvedVerificationIds,
      );
      if (missing.isEmpty) {
        return const _TicketEligibility.eligible();
      }
      firstReason ??= '필수 인증이 필요합니다.';
    }

    return _TicketEligibility.ineligible(
      firstReason ?? '참여 조건이 맞지 않습니다.',
    );
  }

  static List<String> _missingVerificationIds(
    List<String> requiredIds,
    List<String> approvedVerificationIds,
  ) {
    if (requiredIds.isEmpty) return [];
    return requiredIds
        .where((id) => !approvedVerificationIds.contains(id))
        .toList();
  }

  static String? _checkGroupCondition(
    EntryGroup group,
    UserProfile userProfile,
  ) {
    if (group.gender != null) {
      if (userProfile.gender == null) {
        return '성별 정보가 없습니다.';
      }
      if (group.gender != userProfile.gender) {
        return '성별 조건이 맞지 않습니다.';
      }
    }

    final birthYear = userProfile.birthYear ?? userProfile.birthDate?.year;
    if ((group.birthYearMin != null || group.birthYearMax != null) &&
        birthYear == null) {
      return '출생 연도 정보가 없습니다.';
    }

    if (group.birthYearMin != null &&
        birthYear != null &&
        birthYear < group.birthYearMin!) {
      return '${group.birthYearMin}년생 이상만 참여 가능합니다.';
    }

    if (group.birthYearMax != null &&
        birthYear != null &&
        birthYear > group.birthYearMax!) {
      return '${group.birthYearMax}년생 이하만 참여 가능합니다.';
    }

    return null;
  }
}

class _TicketEligibility {
  const _TicketEligibility._({required this.isEligible, this.reason});

  const _TicketEligibility.eligible() : this._(isEligible: true);

  const _TicketEligibility.ineligible(String reason)
    : this._(isEligible: false, reason: reason);

  final bool isEligible;
  final String? reason;
}
