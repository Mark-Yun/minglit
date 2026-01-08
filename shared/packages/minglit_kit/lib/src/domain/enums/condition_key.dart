import 'package:json_annotation/json_annotation.dart';

/// **Condition Key**
///
/// Standard keys for user eligibility/purchase conditions.
enum ConditionKey {
  /// User's gender (male, female)
  @JsonValue('gender')
  gender,

  /// User's age or birth year range
  @JsonValue('age_range')
  ageRange,

  /// Specific occupations
  @JsonValue('occupation')
  occupation,

  /// Residence area
  @JsonValue('residence')
  residence,

  /// MBTI types
  @JsonValue('mbti')
  mbti,
}
