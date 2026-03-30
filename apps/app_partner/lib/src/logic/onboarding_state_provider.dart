import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_state_provider.g.dart';

/// Represents the partner onboarding state for the current user.
enum OnboardingState {
  /// Initial loading state.
  loading,

  /// User has no application and no partner — needs to apply.
  needsApplication,

  /// User has a draft application in progress.
  draftInProgress,

  /// User has submitted and is awaiting review.
  pendingReview,

  /// Admin requested corrections — user needs to resubmit.
  needsCorrection,

  /// User is an active partner.
  hasPartner,
}

@riverpod
Future<OnboardingState> onboardingState(Ref ref) async {
  // Watch auth state so this provider refreshes on login/logout
  final user = ref.watch(currentUserProvider);
  if (user == null) return OnboardingState.needsApplication;

  final partnerRepo = ref.read(partnerRepositoryProvider);

  // Check if user already has a managed partner
  final partners = await partnerRepo.getMyManagedPartners();
  if (partners.isNotEmpty) return OnboardingState.hasPartner;

  // Check application status
  final application = await partnerRepo.getMyApplication();
  if (application == null) return OnboardingState.needsApplication;

  return switch (application.status) {
    'draft' => OnboardingState.draftInProgress,
    'pending' => OnboardingState.pendingReview,
    'needs_correction' => OnboardingState.needsCorrection,
    'approved' => OnboardingState.hasPartner,
    _ => OnboardingState.needsApplication, // rejected or unknown
  };
}
