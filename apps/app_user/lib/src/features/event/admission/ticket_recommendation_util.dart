part of 'event_admission_controller.dart';

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
