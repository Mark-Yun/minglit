import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_application_logic.g.dart';

@riverpod
Future<List<EventApplication>> eventApplications(
  Ref ref,
  String eventId,
) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getApplicationsByEventId(eventId);
}

// Fix #2126: bundle provider for EventApplicationListPage
typedef EventApplicationBundle = ({
  Event event,
  List<EventApplication> applications,
  List<Map<String, dynamic>> groupCounts,
});

@riverpod
Future<EventApplicationBundle> eventApplicationBundle(
  Ref ref,
  String eventId,
) async {
  final repo = ref.watch(eventRepositoryProvider);
  // Fix #2272: start all futures in parallel; await together so any failure is
  // surfaced immediately without leaving unhandled rejected futures.
  final eventFuture = repo.getEventById(eventId);
  final applicationsFuture = repo.getApplicationsByEventId(eventId);
  final groupCountsFuture = repo.getEntryGroupParticipantCounts(eventId);
  await Future.wait([eventFuture, applicationsFuture, groupCountsFuture]);
  final event = await eventFuture;
  final applications = await applicationsFuture;
  final groupCounts = await groupCountsFuture;
  return (
    event: event,
    applications: applications,
    groupCounts: groupCounts,
  );
}

// Fix #2127: carousel queue filtered by groupId (ticket.targetEntryGroupIds)
@riverpod
Future<List<EventApplication>> carouselQueue(
  Ref ref,
  String eventId,
  String? groupId,
) async {
  final all = await ref.watch(eventApplicationsProvider(eventId).future);
  final pending = all.where(
    (a) => a.status == 'pending' || a.status == 'pending_review',
  );
  final filtered = groupId == null
      ? pending
      : pending.where(
          (a) => a.ticket?.targetEntryGroupIds.contains(groupId) ?? false,
        );
  return filtered.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

@riverpod
class EventApplicationReviewController
    extends _$EventApplicationReviewController {
  @override
  FutureOr<void> build() {
    // Nothing to initialize
  }

  Future<void> reviewApplication({
    required String applicationId,
    required String status, // approved, rejected
    String? reason,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Fix #404: Use repository instead of direct Supabase access
      final repo = ref.read(verificationRepositoryProvider);

      // Find the submission ID first via repository.
      final subData = await repo.getSubmissionByApplicationId(applicationId);

      if (subData != null) {
        final submissionId = subData['id'] as String;
        // Fix #301: adminComment removed — will be handled by partner EF (#309)
        await repo.reviewRequest(
          submissionId: submissionId,
          status: status == 'approved'
              ? VerificationStatus.approved
              : VerificationStatus.rejected,
        );
      } else {
        // No submission, handle direct application status update via repository
        await repo.updateApplicationStatus(
          applicationId: applicationId,
          status: status,
          rejectionReason: reason,
        );
      }
    });
  }
}

typedef ReviewMark = ({String status, String? reason});

// Fix #2272: keepAlive so marks survive carousel → confirm page transition
// without a persistent watcher (autoDispose would lose state between pages).
@Riverpod(keepAlive: true)
class ReviewMarkingsNotifier extends _$ReviewMarkingsNotifier {
  @override
  Map<String, ReviewMark> build() => {};

  void addMark(String applicationId, String status, {String? reason}) {
    state = {...state, applicationId: (status: status, reason: reason)};
  }

  void clearAll() => state = {};
}
