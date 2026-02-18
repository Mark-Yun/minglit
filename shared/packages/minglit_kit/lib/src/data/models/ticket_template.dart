import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_template.freezed.dart';
part 'ticket_template.g.dart';

/// Template definition for party ticket settings.
@freezed
abstract class TicketTemplate with _$TicketTemplate {
  /// Creates a [TicketTemplate] for party-level configuration.
  const factory TicketTemplate({
    required String id,
    @JsonKey(name: 'party_id') required String partyId,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    String? description,
    @Default(0) int price,
    @Default(0) int quantity,
    @JsonKey(name: 'target_entry_group_ids')
    @Default([])
    List<String> targetEntryGroupIds,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
  }) = _TicketTemplate;

  /// Creates a [TicketTemplate] from a JSON map.
  factory TicketTemplate.fromJson(Map<String, dynamic> json) =>
      _$TicketTemplateFromJson(json);
}

/// Database-specific helpers for [TicketTemplate].
extension TicketTemplateDbX on TicketTemplate {
  /// Returns JSON suitable for database inserts or updates.
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }
}
