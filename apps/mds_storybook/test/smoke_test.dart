import 'package:flutter_test/flutter_test.dart';
import 'package:mds_storybook/main.dart';

void main() {
  testWidgets('MdsStorybookApp builds without throwing', (tester) async {
    await tester.pumpWidget(const MdsStorybookApp());
    expect(find.byType(MdsStorybookApp), findsOneWidget);
  });
}
