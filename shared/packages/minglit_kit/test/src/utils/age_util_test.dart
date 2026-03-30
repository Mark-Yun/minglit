import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/utils/age_util.dart';

void main() {
  final currentYear = DateTime.now().year;

  group('AgeUtil', () {
    group('calculateKoreanAge', () {
      test('born this year returns 1', () {
        expect(AgeUtil.calculateKoreanAge(currentYear), 1);
      });

      test('born 1 year ago returns 2', () {
        expect(AgeUtil.calculateKoreanAge(currentYear - 1), 2);
      });

      test('born 25 years ago returns 26', () {
        expect(AgeUtil.calculateKoreanAge(currentYear - 25), 26);
      });

      test('born in 1990', () {
        final expected = currentYear - 1990 + 1;
        expect(AgeUtil.calculateKoreanAge(1990), expected);
      });
    });

    group('calculateManAge', () {
      test('born this year returns 0', () {
        expect(AgeUtil.calculateManAge(currentYear), 0);
      });

      test('born 1 year ago returns 1', () {
        expect(AgeUtil.calculateManAge(currentYear - 1), 1);
      });

      test('born 25 years ago returns 25', () {
        expect(AgeUtil.calculateManAge(currentYear - 25), 25);
      });

      test('Korean age is always 1 more than Man age', () {
        for (var year = currentYear - 50; year <= currentYear; year++) {
          final korean = AgeUtil.calculateKoreanAge(year);
          final man = AgeUtil.calculateManAge(year);
          expect(korean - man, 1);
        }
      });
    });
  });
}
