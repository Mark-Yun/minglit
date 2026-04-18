// Fix #1538: FlutterQuill localization delegate 누락 회귀 방지
//
// PartyDescriptionInput(QuillEditor)은 MaterialApp.localizationsDelegates에
// FlutterQuillLocalizations.delegate가 없으면 UnimplementedError를 발생시킨다.
// 이 테스트는 delegate가 포함된 경우 위젯이 정상 렌더링됨을 검증한다.
import 'package:app_partner/src/features/party/widgets/party_description_input.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartyDescriptionInput — Fix #1538', () {
    testWidgets(
      'FlutterQuillLocalizations.delegate 포함 시 크래시 없이 렌더링된다',
      (tester) async {
        final controller = quill.QuillController.basic();
        final focusNode = FocusNode();
        addTearDown(() {
          controller.dispose();
          focusNode.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              // Fix #1538: 이 delegate가 없으면 UnimplementedError 발생
              quill.FlutterQuillLocalizations.delegate,
            ],
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
