import 'package:freezed_annotation/freezed_annotation.dart';

part 'party_entry_group.freezed.dart';
part 'party_entry_group.g.dart';

/// **Party Entry Group**
///
/// Defines a specific group of users allowed to enter the party.
/// e.g. "Male, 20s, Job Verified"
@freezed
abstract class PartyEntryGroup with _$PartyEntryGroup {
  const factory PartyEntryGroup({
    required String id,
    String? label,
    String? gender, // 'male', 'female', null(any)
    @JsonKey(name: 'birth_year_range') Map<String, dynamic>? birthYearRange,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
  }) = _PartyEntryGroup;

  factory PartyEntryGroup.fromJson(Map<String, dynamic> json) =>
      _$PartyEntryGroupFromJson(json);
}
