import 'package:app_partner/src/features/home/widgets/onboarding_step_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _buildGuide({
  required bool hasParty,
  required bool bankAccountReady,
  required VoidCallback onCreateParty,
  required VoidCallback onCreateEvent,
  required VoidCallback onOpenBankAccount,
  String bankVerificationStatus = 'manual_review_approved',
  String? partyName,
  VoidCallback? onOpenGuide,
}) {
  return MaterialApp(
    theme: MinglitTheme.materialTheme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: OnboardingStepGuide(
          hasParty: hasParty,
          bankAccountReady: bankAccountReady,
          bankVerificationStatus: bankVerificationStatus,
          partyName: partyName,
          onOpenBankAccount: onOpenBankAccount,
          onCreateParty: onCreateParty,
          onCreateEvent: onCreateEvent,
          onOpenGuide: onOpenGuide,
        ),
      ),
    ),
  );
}

void main() {
  group('OnboardingStepGuide', () {
    testWidgets(
      'shows 2/4 progress and create-party CTA when bank is ready',
      (tester) async {
        await tester.pumpWidget(
          _buildGuide(
            hasParty: false,
            bankAccountReady: true,
            onOpenBankAccount: () {},
            onCreateParty: () {},
            onCreateEvent: () {},
          ),
        );

        expect(find.text('환영합니다!'), findsOneWidget);
        expect(find.text('2/4 완료'), findsOneWidget);
        expect(find.byIcon(Icons.celebration_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'shows 3/4 progress and partyName and create-event CTA when bank and party are ready',
      (tester) async {
        await tester.pumpWidget(
          _buildGuide(
            hasParty: true,
            bankAccountReady: true,
            partyName: '테스트 파티',
            onOpenBankAccount: () {},
            onCreateParty: () {},
            onCreateEvent: () {},
          ),
        );

        expect(find.text('3/4 완료'), findsOneWidget);
        expect(find.text('테스트 파티'), findsOneWidget);
        expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'keeps account step current while verification is pending',
      (tester) async {
        var openBankCount = 0;

        await tester.pumpWidget(
          _buildGuide(
            hasParty: false,
            bankAccountReady: false,
            bankVerificationStatus: 'manual_review_pending',
            onOpenBankAccount: () => openBankCount++,
            onCreateParty: () {},
            onCreateEvent: () {},
          ),
        );

        expect(find.text('1/4 완료'), findsOneWidget);
        expect(find.text('계좌 확인 중'), findsOneWidget);
        expect(find.text('운영 확인이 완료되면 사라져요'), findsOneWidget);

        await tester.tap(find.text('계좌 확인 중'));
        expect(openBankCount, 1);
      },
    );

    testWidgets(
      'calls onCreateParty when CTA button is tapped',
      (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          _buildGuide(
            hasParty: false,
            bankAccountReady: true,
            onOpenBankAccount: () {},
            onCreateParty: () => callCount++,
            onCreateEvent: () {},
          ),
        );

        await tester.tap(find.byIcon(Icons.celebration_outlined));
        expect(callCount, 1);
      },
    );

    testWidgets(
      'calls onCreateEvent when CTA button is tapped',
      (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          _buildGuide(
            hasParty: true,
            bankAccountReady: true,
            partyName: '테스트 파티',
            onOpenBankAccount: () {},
            onCreateParty: () {},
            onCreateEvent: () => callCount++,
          ),
        );

        await tester.tap(find.byIcon(Icons.event_outlined));
        expect(callCount, 1);
      },
    );

    testWidgets('calls onOpenGuide callback when guide button tapped', (
      tester,
    ) async {
      var callCount = 0;

      await tester.pumpWidget(
        _buildGuide(
          hasParty: false,
          bankAccountReady: true,
          onOpenBankAccount: () {},
          onCreateParty: () {},
          onCreateEvent: () {},
          onOpenGuide: () => callCount++,
        ),
      );

      await tester.tap(find.text('도움말 보기'));
      expect(callCount, 1);
    });
  });
}
