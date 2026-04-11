import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// **Tag Model**
///
/// Represents a discoverable tag that can be associated with parties.
@freezed
abstract class Tag with _$Tag {
  /// Creates a [Tag] with core metadata.
  const factory Tag({
    required String id,
    required String name,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    // Fix #1224: recent_count is the 7-day trending metric returned by the
    // get_trending_tags RPC. Defaults to 0 so non-RPC sources (e.g. plain
    // tag list) remain compatible without schema changes.
    @JsonKey(name: 'recent_count') @Default(0) int recentCount,
  }) = _Tag;

  /// Creates a [Tag] from a JSON map.
  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
