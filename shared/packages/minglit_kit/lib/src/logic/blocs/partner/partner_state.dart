import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../data/models/partner_application.dart';

part 'partner_state.freezed.dart';

@freezed
class PartnerState with _$PartnerState {
  const factory PartnerState.initial() = _Initial;
  const factory PartnerState.loading() = _Loading;
  const factory PartnerState.applicationLoaded(PartnerApplication? application) = _ApplicationLoaded;
  const factory PartnerState.membersLoaded(List<Map<String, dynamic>> members) = _MembersLoaded;
  const factory PartnerState.success() = _Success;
  const factory PartnerState.failure(String message) = _Failure;
}
