// Fix #1538: FlutterQuill localization delegate 누락 회귀 방지
//
// PartyDescriptionInput(QuillEditor)은 MaterialApp.localizationsDelegates에
// FlutterQuillLocalizations.delegate가 없으면 UnimplementedError를 발생시킨다.
// kPartnerLocalizationsDelegates(main.dart의 production 목록)를 직접 사용하므로
// main.dart에서 delegate가 제거되면 이 테스트도 실패한다.
import 'package:app_partner/main.dart' show kPartnerLocalizationsDelegates;
import 'package:app_partner/src/features/party/widgets/party_description_input.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartyDescriptionInput — Fix #1538', () {
    testWidgets(
      'production localizationsDelegates(kPartnerLocalizationsDelegates) 포함 시 크래시 없이 렌더링된다',
      (tester) async {
        final controller = quill.QuillController.basic();
        final focusNode = FocusNode();
        addTearDown(() {
          controller.dispose();
          focusNode.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            // Fix #1538: main.dart의 production delegate 목록을 그대로 사용.
            // delegate가 main.dart에서 제거되면 이 테스트도 실패하여 회귀를 감지한다.
            localizationsDelegates: kPartnerLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PartyDescriptionInput(
                quillController: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PartyDescriptionInput), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
