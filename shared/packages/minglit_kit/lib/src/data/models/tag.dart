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
  }) = _Tag;

  /// Creates a [Tag] from a JSON map.
  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
