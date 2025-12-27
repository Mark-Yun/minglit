import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'partner_event.freezed.dart';

@freezed
class PartnerEvent with _$PartnerEvent {
  const factory PartnerEvent.checkApplicationStatus() = _CheckApplicationStatus;
  const factory PartnerEvent.submitApplication({
    required Map<String, dynamic> applicationData,
    required XFile bizRegistrationFile,
    required XFile bankbookFile,
  }) = _SubmitApplication;

  const factory PartnerEvent.loadMembers({required String partnerId}) =
      _LoadMembers;

  // --- Admin Features ---
  const factory PartnerEvent.loadAllApplications({
    @Default('all') String status,
    String? searchTerm,
  }) = _LoadAllApplications;

  const factory PartnerEvent.reviewApplication({
    required String applicationId,
    required String status,
    String? adminComment,
  }) = _ReviewApplication;
}
