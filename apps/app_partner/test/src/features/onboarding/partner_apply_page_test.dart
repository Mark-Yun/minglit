import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/features/onboarding/partner_apply_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  late MockPartnerRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const PartnerApplication(id: '', userId: ''));
  });

  setUp(() {
    mockRepo = MockPartnerRepository();
    when(() => mockRepo.getMyApplication()).thenAnswer((_) async => null);
    when(() => mockRepo.saveDraft(any())).thenAnswer(
      (_) async => const PartnerApplication(id: 'draft_id', userId: 'user_1'),
    );
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        partnerRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerApplyPage(),
      ),
    );
  }

  group('PartnerApplyPage', () {
    testWidgets('renders progress indicator on step 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(MinglitLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('"다음" button exists on step 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('"이전" button is hidden on step 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('이전'), findsNothing);
    });

    testWidgets('"이전" button appears after moving to step 1', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final element = tester.element(find.byType(PartnerApplyPage));
      ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider.notifier).setStep(1);

      await tester.pumpAndSettle();

      expect(find.text('이전'), findsOneWidget);
    });

    testWidgets('"신청하기" button exists on step 4', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final element = tester.element(find.byType(PartnerApplyPage));
      ProviderScope.containerOf(
        element,
      ).read(partnerApplyControllerProvider.notifier).setStep(4);

      await tester.pumpAndSettle();

      expect(find.text('신청하기'), findsOneWidget);
    });
  });
}
