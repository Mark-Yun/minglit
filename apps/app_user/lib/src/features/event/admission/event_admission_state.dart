part of 'event_admission_controller.dart';

enum EventAdmissionStatus {
  guest, // 로그인 필요
  identityRequired, // 본인인증 필요 (기본 신뢰)
  qualificationRequired, // 자격 심사 필요 (직장, 학력 등)
  notEligible, // 나이/성별 조건 미달 (이 이벤트의 모든 티켓에 대해)
  eligible, // 조건 만족 (티켓 구매 가능)
  fullOrSoldOut, // Fix #1211: 정원 마감 — currentParticipants >= maxParticipants
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

enum AdmissionButtonStyle {
  normal,
  disabled,
  destructive,
}

class AdmissionButtonConfig {
  const AdmissionButtonConfig({
    required this.label,
    this.enabled = true,
    this.style = AdmissionButtonStyle.normal,
  });

  final String label;
  final bool enabled;
  final AdmissionButtonStyle style;
}

/// Checks eligibility across all tickets and entry groups.
///
/// Returns an [AdmissionState] based on the user's profile and verifications.
AdmissionState _checkEligibility({
  required List<Ticket> tickets,
  required List<EntryGroup> entryGroups,
  required UserProfile userProfile,
  required List<String> userVerifIds,
  required User currentUser,
}) {
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
  final birthDate = user.birthDate;
  if (birthDate == null) return '생년월일 정보가 없습니다.';

  final birthYear = birthDate.year;
  if (group.birthYearMin != null && birthYear < group.birthYearMin!) {
    return '${group.birthYearMin}년생 이상만 참여 가능합니다.';
  }
  if (group.birthYearMax != null && birthYear > group.birthYearMax!) {
    return '${group.birthYearMax}년생 이하만 참여 가능합니다.';
  }

  return null; // OK
}
