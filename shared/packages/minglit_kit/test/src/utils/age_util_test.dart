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

      test(
        'Korean age is always 1 more than Man age (year-only approximation)',
        () {
          for (var year = currentYear - 50; year <= currentYear; year++) {
            final korean = AgeUtil.calculateKoreanAge(year);
            final man = AgeUtil.calculateManAge(year);
            expect(korean - man, 1);
          }
        },
      );
    });

    group('calculateManAgeFromDate', () {
      test('birthday today → age is exact', () {
        final now = DateTime.now();
        final birthDate = DateTime(now.year - 30, now.month, now.day);
        expect(AgeUtil.calculateManAgeFromDate(birthDate), 30);
      });

      test('birthday yesterday → age is exact (birthday passed)', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        // Fix #2004: on Jan 1, yesterday wraps to Dec 31 of the previous year,
        // making the birth date appear to be in the future. Skip that edge case —
        // it is untestable without clock injection.
        if (yesterday.year != now.year) return;
        final birthDate = DateTime(
          now.year - 30,
          yesterday.month,
          yesterday.day,
        );
        expect(AgeUtil.calculateManAgeFromDate(birthDate), 30);
      });

      test('birthday tomorrow → age is one less (birthday not yet passed)', () {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        // Fix #2004: on Dec 31, tomorrow wraps to Jan 1 of the next year,
        // making the birth date appear to be in the past. Skip that edge case —
        // it is untestable without clock injection.
        if (tomorrow.year != now.year) return;
        final birthDate = DateTime(now.year - 30, tomorrow.month, tomorrow.day);
        expect(AgeUtil.calculateManAgeFromDate(birthDate), 29);
      });

      test(
        'born Nov 15 1995: correct 만 age based on whether today is before or after Nov 15',
        () {
          // Fix #1963: year-only gives currentYear-1995, but correct 만 age is
          // 1 less if birthday hasn't passed yet in the current year.
          final birthDate = DateTime(1995, 11, 15);
          final now = DateTime.now();
          final birthdayPassed =
              (now.month > 11) || (now.month == 11 && now.day >= 15);
          final expected = birthdayPassed
              ? now.year - 1995
              : now.year - 1995 - 1;
          expect(AgeUtil.calculateManAgeFromDate(birthDate), expected);
        },
      );

      test('age 0 on birth year, birthday today', () {
        final now = DateTime.now();
        final birthDate = DateTime(now.year, now.month, now.day);
        expect(AgeUtil.calculateManAgeFromDate(birthDate), 0);
      });
    });
  });
}
