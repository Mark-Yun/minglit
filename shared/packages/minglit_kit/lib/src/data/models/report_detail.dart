import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';

part 'report_detail.freezed.dart';
part 'report_detail.g.dart';

enum ReportReason {
  sexualContent('sexual_content'),
  falseInformation('false_information'),
  noShow('no_show'),
  fraud('fraud'),
  other('other');

  const ReportReason(this.value);
  final String value;
}

@freezed
abstract class ReportDetail with _$ReportDetail {
  const factory ReportDetail({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'target_id') required String targetId,
    @JsonKey(name: 'target_type') required SocialTargetType targetType,
    required String reason,
    String? description,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ReportDetail;

  factory ReportDetail.fromJson(Map<String, dynamic> json) =>
      _$ReportDetailFromJson(json);
}
