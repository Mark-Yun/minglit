import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingState', () {
    test('has exactly 6 enum values', () {
      expect(OnboardingState.values.length, 6);
    });

    test('hasPartner is a valid enum value', () {
      expect(OnboardingState.hasPartner, isA<OnboardingState>());
    });

    test('needsApplication is a valid enum value', () {
      expect(OnboardingState.needsApplication, isA<OnboardingState>());
    });

    test('all 6 expected values exist', () {
      expect(
        OnboardingState.values,
        containsAll([
          OnboardingState.loading,
          OnboardingState.needsApplication,
          OnboardingState.draftInProgress,
          OnboardingState.pendingReview,
          OnboardingState.needsCorrection,
          OnboardingState.hasPartner,
        ]),
      );
    });

    test('enum values have correct names', () {
      expect(OnboardingState.loading.name, 'loading');
      expect(OnboardingState.needsApplication.name, 'needsApplication');
      expect(OnboardingState.draftInProgress.name, 'draftInProgress');
      expect(OnboardingState.pendingReview.name, 'pendingReview');
      expect(OnboardingState.needsCorrection.name, 'needsCorrection');
      expect(OnboardingState.hasPartner.name, 'hasPartner');
    });
  });
}
