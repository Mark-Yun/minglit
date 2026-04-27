/// Utility for age calculations.
class AgeUtil {
  /// Calculates the Korean age (year-based) for a given birth year.
  /// Result is (Current Year - birthYear + 1).
  static int calculateKoreanAge(int birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - birthYear + 1;
  }

  /// Calculates 만 age (international age) from birth year only.
  ///
  /// **Limitation**: Result may be off by 1 if the birthday has not yet
  /// passed in the current year. When only birth year is available, the
  /// result is `currentYear - birthYear`, which is correct after the
  /// birthday but 1 too high before it. Do not use for hard age-gate
  /// enforcement — use [calculateManAgeFromDate] when full DOB is available.
  // Fix #1963: document ±1 year limitation when only birth year is stored
  static int calculateManAge(int birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - birthYear;
  }

  /// Calculates 만 age (international age) accurately from a full birth date.
  ///
  /// Returns `currentYear - birthYear - 1` if today is before this year's
  /// birthday, otherwise `currentYear - birthYear`. Prefer this over
  /// [calculateManAge] whenever the full date of birth is available.
  // Fix #1963: accurate 만 age accounting for whether birthday has passed
  static int calculateManAgeFromDate(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    final birthdayPassedThisYear =
        (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    return birthdayPassedThisYear ? age : age - 1;
  }
}
