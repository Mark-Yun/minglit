import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_application_controller.g.dart';

@riverpod
Future<List<EventApplication>> eventApplications(
  Ref ref,
  String eventId,
) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getApplicationsByEventId(eventId);
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
