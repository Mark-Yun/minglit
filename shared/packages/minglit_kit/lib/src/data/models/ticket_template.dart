import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_template.freezed.dart';
part 'ticket_template.g.dart';

@freezed
abstract class TicketTemplate with _$TicketTemplate {
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

  factory TicketTemplate.fromJson(Map<String, dynamic> json) =>
      _$TicketTemplateFromJson(json);
}

extension TicketTemplateDbX on TicketTemplate {
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }
}
