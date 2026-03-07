import 'dart:async';

import 'package:app_partner/src/features/onboarding/partner_apply_status_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  group('PartnerApplyStatusPage', () {
    late MockPartnerRepository mockRepo;

    setUp(() {
      mockRepo = MockPartnerRepository();
    });

    /// Builds the widget under test with the given provider overrides.
    ///
    /// Uses [SynchronousFuture] for [getMyApplication] so the anonymous
    /// inline FutureProvider in [PartnerApplyStatusPage] resolves immediately
    /// without triggering an infinite rebuild loop in tests.
    Widget buildWidget({required List<dynamic> overrides}) {
      return ProviderScope(
        overrides: overrides.cast(),
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ko'),
          home: PartnerApplyStatusPage(),
        ),
      );
    }

    testWidgets(
      'shows loading indicator when onboardingStateProvider is loading',
      (tester) async {
        // Stub getMyApplication so the inline FutureProvider can call it.
        when(
          () => mockRepo.getMyApplication(),
        ).thenAnswer((_) => SynchronousFuture<PartnerApplication?>(null));

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              partnerRepositoryProvider.overrideWith((ref) => mockRepo),
              // A Completer that never resolves keeps the provider loading.
              onboardingStateProvider.overrideWith(
                (ref) => Completer<OnboardingState>().future,
              ),
            ],
          ),
        );

        // One pump — onboarding future is still pending.
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'shows pending message when state is pendingReview',
      (tester) async {
        // SynchronousFuture resolves the inline FutureProvider immediately
        // so the widget never enters the applicationAsync loading state.
        when(() => mockRepo.getMyApplication()).thenAnswer(
          (_) => SynchronousFuture<PartnerApplication?>(
            const PartnerApplication(
              id: 'app_1',
              userId: 'user_1',
              status: 'pending',
            ),
          ),
        );

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              partnerRepositoryProvider.overrideWith((ref) => mockRepo),
              onboardingStateProvider.overrideWith(
                (ref) => SynchronousFuture(OnboardingState.pendingReview),
              ),
            ],
          ),
        );

        // Two pumps: one for onboarding to resolve, one for widget rebuild.
        await tester.pump();
        await tester.pump();

        // Korean: '심사 중입니다. 영업일 기준 3~5일 내에 결과를 알려드립니다.'
        expect(find.textContaining('심사 중입니다'), findsOneWidget);
      },
    );

    testWidgets(
      'shows needsCorrection message and admin comment',
      (tester) async {
        const adminComment = '사업자 등록증을 다시 제출해주세요.';

        when(() => mockRepo.getMyApplication()).thenAnswer(
          (_) => SynchronousFuture<PartnerApplication?>(
            const PartnerApplication(
              id: 'app_2',
              userId: 'user_2',
              status: 'needs_correction',
              adminComment: adminComment,
            ),
          ),
        );

        await tester.pumpWidget(
          buildWidget(
            overrides: [
              partnerRepositoryProvider.overrideWith((ref) => mockRepo),
              onboardingStateProvider.overrideWith(
                (ref) => SynchronousFuture(OnboardingState.needsCorrection),
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pump();

        // Korean: '보완이 필요합니다. 아래 내용을 확인하고 수정해주세요.'
        expect(find.textContaining('보완이 필요합니다'), findsOneWidget);
        // Admin comment text is displayed.
        expect(find.text(adminComment), findsOneWidget);
      },
    );
  });
}
