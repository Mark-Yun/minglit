import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'partner_event.freezed.dart';

@freezed
class PartnerEvent with _$PartnerEvent {
  const factory PartnerEvent.checkApplicationStatus() = _CheckApplicationStatus;
  const factory PartnerEvent.submitApplication({
    required Map<String, dynamic> data,
    required XFile bizRegistrationFile,
    required XFile bankbookFile,
  }) = _SubmitApplication;
  const factory PartnerEvent.loadMembers(String partnerId) = _LoadMembers;
}
