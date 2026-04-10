part of 'event_admission_controller.dart';

/// Extension methods for EventAdmissionController button configuration.
///
/// Extracted from the controller to keep file sizes manageable.
/// Pure mapping from state to button config — no ref/state access needed.
extension AdmissionActions on EventAdmissionController {
  AdmissionButtonConfig buttonConfig(AdmissionState state) {
    switch (state.status) {
      case EventAdmissionStatus.guest:
        return const AdmissionButtonConfig(label: '로그인하고 신청하기');
      case EventAdmissionStatus.identityRequired:
        return const AdmissionButtonConfig(label: '본인인증 후 신청하기');
      case EventAdmissionStatus.qualificationRequired:
        return const AdmissionButtonConfig(label: '신청하기');
      case EventAdmissionStatus.notEligible:
        return AdmissionButtonConfig(
          label: state.ineligibleReason ?? '참여 조건 미달',
          enabled: false,
          style: AdmissionButtonStyle.disabled,
        );
      case EventAdmissionStatus.eligible:
        return const AdmissionButtonConfig(label: '참가 신청하기');
      case EventAdmissionStatus.fullOrSoldOut:
        return const AdmissionButtonConfig(
          label: '마감된 이벤트',
          enabled: false,
          style: AdmissionButtonStyle.disabled,
        );
      case EventAdmissionStatus.pendingPayment:
        return const AdmissionButtonConfig(label: '결제 계속하기');
      case EventAdmissionStatus.applied:
        return const AdmissionButtonConfig(label: '이미 신청한 이벤트');
      case EventAdmissionStatus.rejected:
        return const AdmissionButtonConfig(
          label: '심사 반려 (사유 확인)',
          style: AdmissionButtonStyle.destructive,
        );
      // Fix #1208: Ended event button configs
      case EventAdmissionStatus.eventEnded:
        return const AdmissionButtonConfig(
          label: '종료된 이벤트',
          enabled: false,
          style: AdmissionButtonStyle.disabled,
        );
      case EventAdmissionStatus.eventEndedWithResults:
        return const AdmissionButtonConfig(label: '매칭 결과 보기');
      case EventAdmissionStatus.eventEndedParticipated:
        return const AdmissionButtonConfig(
          label: '참여 완료',
          enabled: false,
          style: AdmissionButtonStyle.disabled,
        );
    }
  }
}
