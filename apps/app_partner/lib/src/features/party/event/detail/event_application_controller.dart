import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final repo = ref.read(verificationRepositoryProvider);

      // Find the submission ID first.
      final supabase = Supabase.instance.client;
      final subData = await supabase
          .from('verification_submissions')
          .select('id')
          .eq('application_id', applicationId)
          .maybeSingle();

      if (subData != null) {
        final submissionId = subData['id'] as String;
        await repo.reviewRequest(
          submissionId: submissionId,
          status: status == 'approved'
              ? VerificationStatus.approved
              : VerificationStatus.rejected,
          adminComment: reason,
        );
      } else {
        // No submission, handle direct application status update
        await supabase
            .from('event_applications')
            .update({
              'status': status,
              'rejection_reason': reason,
            })
            .eq('id', applicationId);
      }
    });
  }
}
