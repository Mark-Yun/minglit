import 'package:freezed_annotation/freezed_annotation.dart';

part 'deletion_status.freezed.dart';
part 'deletion_status.g.dart';

const _gracePeriod = Duration(days: 7);

/// The current account deletion state for the signed-in user.
@freezed
abstract class DeletionStatus with _$DeletionStatus {
  /// Creates a [DeletionStatus].
  const factory DeletionStatus({
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'grace_period_ends') DateTime? gracePeriodEnds,
    @Default(false) bool isPending,
  }) = _DeletionStatus;

  /// Creates a [DeletionStatus] from JSON.
  factory DeletionStatus.fromJson(Map<String, dynamic> json) =>
      _$DeletionStatusFromJson(json);

  /// Creates a pending/non-pending status from the `deleted_at` column.
  factory DeletionStatus.fromDeletedAt(DateTime? deletedAt) {
    return DeletionStatus(
      deletedAt: deletedAt,
      gracePeriodEnds: deletedAt?.add(_gracePeriod),
      isPending: deletedAt != null,
    );
  }
}
