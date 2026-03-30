/// Utility for age calculations.
class AgeUtil {
  /// Calculates the Korean age (year-based) for a given birth year.
  /// Result is (Current Year - birthYear + 1).
  static int calculateKoreanAge(int birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - birthYear + 1;
  }

  /// Calculates the "Man" age (International age) for a given birth year.
  static int calculateManAge(int birthYear) {
    final currentYear = DateTime.now().year;
    return currentYear - birthYear;
  }
}
