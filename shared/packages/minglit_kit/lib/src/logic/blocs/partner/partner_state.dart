import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart' show PartnerBloc;
import 'package:minglit_kit/src/data/models/partner_application.dart';
import 'package:minglit_kit/src/logic/blocs/partner/partner_bloc.dart'
    show PartnerBloc;

part 'partner_state.freezed.dart';

/// States for [PartnerBloc].
@freezed
class PartnerState with _$PartnerState {
  /// Initial state.
  const factory PartnerState.initial() = _Initial;

  /// Loading state.
  const factory PartnerState.loading() = _Loading;

  /// Application status loaded.
  const factory PartnerState.applicationLoaded(
    PartnerApplication? application,
  ) = _ApplicationLoaded;

  /// Member list loaded.
  const factory PartnerState.membersLoaded(
    List<Map<String, dynamic>> members,
  ) = _MembersLoaded;

  /// Generic success state.
  const factory PartnerState.success() = _Success;

  /// Operation failed.
  const factory PartnerState.failure(String message) = _Failure;
}
