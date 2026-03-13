import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';

part 'report_detail.freezed.dart';
part 'report_detail.g.dart';

/// Reason categories for reporting a partner.
enum ReportReason {
  /// Sexual or inappropriate content.
  sexualContent('sexual_content'),

  /// False or misleading information.
  falseInformation('false_information'),

  /// No-show at an event.
  noShow('no_show'),

  /// Fraudulent activity.
  fraud('fraud'),

  /// Other reason (requires description).
  other('other'),
  ;

  /// Creates a [ReportReason] with the given DB [value].
  const ReportReason(this.value);

  /// The raw string value stored in the database.
  final String value;
}

/// Detailed record of a user report against a target.
@freezed
abstract class ReportDetail with _$ReportDetail {
  /// Creates a [ReportDetail].
  const factory ReportDetail({
    /// Unique identifier.
    required String id,

    /// ID of the reporting user.
    @JsonKey(name: 'user_id') required String userId,

    /// ID of the reported target.
    @JsonKey(name: 'target_id') required String targetId,

    /// Type of the reported target.
    @JsonKey(name: 'target_type') required SocialTargetType targetType,

    /// Reason category for the report.
    required String reason,

    /// When the report was created.
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Optional free-text description.
    String? description,
  }) = _ReportDetail;

  /// Creates a [ReportDetail] from a JSON map.
  factory ReportDetail.fromJson(Map<String, dynamic> json) =>
      _$ReportDetailFromJson(json);
}
