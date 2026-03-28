import 'package:app_partner/src/features/home/widgets/onboarding_step_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingStepGuide', () {
    testWidgets(
      'shows welcome message and 2/4 progress and create-party CTA when hasParty is false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OnboardingStepGuide(
                  hasParty: false,
                  partyName: null,
                  onCreateParty: () {},
                  onCreateEvent: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('환영합니다!'), findsOneWidget);
        expect(find.text('2/4 완료'), findsOneWidget);
        // CTA icon uniquely identifies the FilledButton.icon in the hasParty=false state.
        expect(find.byIcon(Icons.celebration_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'shows 3/4 progress and partyName and create-event CTA when hasParty is true',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OnboardingStepGuide(
                  hasParty: true,
                  partyName: '테스트 파티',
                  onCreateParty: () {},
                  onCreateEvent: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('3/4 완료'), findsOneWidget);
        expect(find.text('테스트 파티'), findsOneWidget);
        // CTA icon uniquely identifies the FilledButton.icon in the hasParty=true state.
        expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'calls onCreateParty callback when CTA button tapped and hasParty is false',
      (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OnboardingStepGuide(
                  hasParty: false,
                  partyName: null,
                  onCreateParty: () => callCount++,
                  onCreateEvent: () {},
                ),
              ),
            ),
          ),
        );

        // Tap the CTA via its unique icon (celebration = create party).
        await tester.tap(find.byIcon(Icons.celebration_outlined));
        expect(callCount, 1);
      },
    );

    testWidgets(
      'calls onCreateEvent callback when CTA button tapped and hasParty is true',
      (tester) async {
        var callCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OnboardingStepGuide(
                  hasParty: true,
                  partyName: '테스트 파티',
                  onCreateParty: () {},
                  onCreateEvent: () => callCount++,
                ),
              ),
            ),
          ),
        );

        // Tap the CTA via its unique icon (event_outlined = create event).
        await tester.tap(find.byIcon(Icons.event_outlined));
        expect(callCount, 1);
      },
    );
  });
}
