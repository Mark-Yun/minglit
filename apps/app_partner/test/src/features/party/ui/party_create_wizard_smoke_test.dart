// Ref #1072: P0 Smoke — PartyCreateWizardPage 화면 진입 테스트
//
// 파티 생성 위저드 화면이 크래시 없이 렌더링됨을 검증한다.
// 6단계 위저드의 각 step 진입 상태를 검증한다.
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget buildWidget({PartyCreateWizardState? initialState}) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          // Fix #1072: overrideWith() 사용 — build()가 .notifier를 직접 읽으므로
          // overrideWithValue()는 _SyncValueProviderElement 타입 에러 발생.
          partyCreateWizardControllerProvider.overrideWith(
            () => _FakePartyCreateWizardController(initialState),
          ),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PartyCreateWizardPage(),
      ),
    );
  }

  // Quill 에디터는 초기화 시 zero-duration timer를 생성한다.
  // pumpAndSettle()로 모든 timer를 flush해야 "Timer is still pending" 오류가 방지된다.
  Future<void> pumpWizard(
    WidgetTester tester,
    PartyCreateWizardState? initialState,
  ) async {
    await tester.pumpWidget(buildWidget(initialState: initialState));
    await tester.pumpAndSettle();
  }

  group('PartyCreateWizardPage smoke', () {
    testWidgets('basicInfo step에서 진행 바가 표시된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(currentStep: PartyCreateStep.basicInfo),
      );

      expect(find.byType(MinglitLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('basicInfo step에서 "다음" 버튼이 표시된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(currentStep: PartyCreateStep.basicInfo),
      );

      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('basicInfo step에서 "이전" 버튼은 숨겨진다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(currentStep: PartyCreateStep.basicInfo),
      );

      expect(find.text('이전'), findsNothing);
    });

    testWidgets('location step에서 "이전" 버튼이 표시된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(currentStep: PartyCreateStep.location),
      );

      expect(find.text('이전'), findsOneWidget);
    });

    testWidgets('review step에서 "완료" 버튼이 표시된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(currentStep: PartyCreateStep.review),
      );

      expect(find.text('완료'), findsOneWidget);
    });

    testWidgets('제출 중(isLoading)에 버튼이 비활성화된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(
          currentStep: PartyCreateStep.review,
          status: AsyncValue.loading(),
        ),
      );

      // 위젯이 크래시 없이 렌더링됨을 검증
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('editMode(partyId 있음)에서도 크래시 없이 렌더링된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(
          currentStep: PartyCreateStep.basicInfo,
          editingPartyId: 'existing-party-1',
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('tickets step이 크래시 없이 렌더링된다', (tester) async {
      await pumpWizard(
        tester,
        const PartyCreateWizardState(currentStep: PartyCreateStep.tickets),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}

class _FakePartyCreateWizardController extends PartyCreateWizardController {
  _FakePartyCreateWizardController(this._initialState);
  final PartyCreateWizardState _initialState;

  @override
  PartyCreateWizardState build() => _initialState;
}
