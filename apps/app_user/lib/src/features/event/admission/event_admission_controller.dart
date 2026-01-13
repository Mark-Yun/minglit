import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_admission_controller.g.dart';

enum EventAdmissionStatus {
  guest, // 로그인 필요
  identityRequired, // 본인인증 필요 (기본 신뢰)
  notEligible, // 나이/성별 조건 미달 (이 이벤트의 모든 티켓에 대해)
  eligible, // 조건 만족 (티켓 구매 가능) -> 티켓 선택 시 추가 심사 여부 판별
  applied, // 이미 신청함/참여중
}

/// **Admission State**
///
/// Holds the calculated status and detailed reasons.
class AdmissionState {
  AdmissionState({
    required this.status,
    this.user,
    this.ineligibleReason,
  });

  final EventAdmissionStatus status;
  final User? user;
  final String? ineligibleReason;
}

@riverpod
class EventAdmissionController extends _$EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    final currentUser = ref.watch(currentUserProvider);
    final repository = ref.watch(eventRepositoryProvider);

    // 1. Check Login
    if (currentUser == null) {
      return AdmissionState(status: EventAdmissionStatus.guest);
    }

    // 2. Check Existing Application (DB Check)
    final hasApplied = await repository.checkApplicationStatus(
      eventId: event.id,
      userId: currentUser.id,
    );

    if (hasApplied) {
      return AdmissionState(
        status: EventAdmissionStatus.applied,
        user: currentUser,
      );
    }

    // 3. Fetch User Profile (Identity Check)
    // We need birth_date and gender from user_profiles.
    final userProfile = await _fetchUserProfile(currentUser.id);

    if (userProfile == null || !userProfile.isVerified) {
      return AdmissionState(
        status: EventAdmissionStatus.identityRequired,
        user: currentUser,
      );
    }

    // 4. Check Eligibility (Age/Gender)
    // Event has multiple tickets, each linked to EntryGroups.
    // User is eligible if they match AT LEAST ONE ticket's condition.
    final tickets = event.tickets ?? [];
    final entryGroups = event.entryGroups ?? [];

    if (tickets.isEmpty) {
      // No tickets? Should not happen for active event.
      return AdmissionState(
        status: EventAdmissionStatus.eligible,
        user: currentUser,
      );
    }

    var isAnyEligible = false;
    String? firstReason;

    for (final ticket in tickets) {
      // Find linked groups
      final groups = entryGroups
          .where((g) => ticket.targetEntryGroupIds.contains(g.id))
          .toList();

      // If no groups linked, it means "Open to All" (or misconfig).
      // Assume open.
      if (groups.isEmpty) {
        isAnyEligible = true;
        break;
      }

      // Check each group condition
      for (final group in groups) {
        final reason = _checkGroupCondition(group, userProfile);
        if (reason == null) {
          isAnyEligible = true;
          break; // Matches this ticket
        } else {
          firstReason ??= reason;
        }
      }
      if (isAnyEligible) break;
    }
    if (!isAnyEligible) {
      return AdmissionState(
        status: EventAdmissionStatus.notEligible,
        user: currentUser,
        ineligibleReason: firstReason ?? '참여 조건이 맞지 않습니다.',
      );
    }

    // 5. Eligible
    return AdmissionState(
      status: EventAdmissionStatus.eligible,
      user: currentUser,
    );
  }

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    // Ideally this should be in a Repository
    final supabase = ref.read(supabaseClientProvider);
    try {
      final data = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(data);
    } on Object {
      return null;
    }
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
