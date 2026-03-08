import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Parsed user eligibility data from `get_bulk_eligibility_data` RPC.
class BulkEligibilityData {
  const BulkEligibilityData({
    required this.userProfile,
    required this.approvedVerificationIds,
  });

  /// Creates from the raw JSON returned by the RPC.
  factory BulkEligibilityData.fromJson(Map<String, dynamic> json) {
    final profileJson = json['user_profile'] as Map<String, dynamic>?;
    final verifications =
        (json['approved_verifications'] as List<dynamic>?) ?? [];

    UserProfile? profile;
    if (profileJson != null) {
      profile = UserProfile(
        id: '',
        name: '',
        username: '',
        gender: profileJson['gender'] as String?,
        birthYear: profileJson['birth_year'] as int?,
        isVerified: profileJson['is_verified'] as bool? ?? false,
      );
    }

    final verificationIds = verifications
        .map((v) => (v as Map<String, dynamic>)['verification_id'] as String)
        .toList();

    return BulkEligibilityData(
      userProfile: profile,
      approvedVerificationIds: verificationIds,
    );
  }

  final UserProfile? userProfile;
  final List<String> approvedVerificationIds;
}

/// Client-side eligibility filter.
///
/// Uses [TicketRecommendationUtil] to determine if a user is eligible
/// for at least one ticket of each event.
class EligibilityFilter {
  const EligibilityFilter._();

  /// Filters a list of events, keeping only those where the user
  /// has at least one eligible ticket.
  ///
  /// `balanceStatus` maps ticket_id → allowed. If empty, all tickets
  /// are assumed to be balance-allowed (no gender balance restriction).
  static List<Event> filter({
    required List<Event> events,
    required BulkEligibilityData eligibilityData,
    Map<String, Map<String, bool>> balanceStatusByEvent = const {},
  }) {
    if (eligibilityData.userProfile == null) return [];

    return events.where((event) {
      final tickets = event.tickets;
      if (tickets == null || tickets.isEmpty) {
        // Events without tickets are always eligible (free/open)
        return true;
      }

      final eventBalance =
          balanceStatusByEvent[event.id] ?? _allAllowed(tickets);

      final result = TicketRecommendationUtil.recommend(
        event: event,
        userProfile: eligibilityData.userProfile,
        approvedVerificationIds: eligibilityData.approvedVerificationIds,
        balanceStatus: eventBalance,
      );

      return result.eligibleTickets.isNotEmpty;
    }).toList();
  }

  /// Creates a default balance map where all tickets are allowed.
  static Map<String, bool> _allAllowed(List<Ticket> tickets) {
    return {for (final t in tickets) t.id: true};
  }
}
