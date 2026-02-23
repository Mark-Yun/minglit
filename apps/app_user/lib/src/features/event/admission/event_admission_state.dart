part of 'event_admission_controller.dart';

enum EventAdmissionStatus {
  guest, // 로그인 필요
  identityRequired, // 본인인증 필요 (기본 신뢰)
  qualificationRequired, // 자격 심사 필요 (직장, 학력 등)
  notEligible, // 나이/성별 조건 미달 (이 이벤트의 모든 티켓에 대해)
  eligible, // 조건 만족 (티켓 구매 가능)
  pendingPayment, // 결제 미완료 (이어하기)
  applied, // 이미 신청함/참여중 (결제 완료/심사 대기/승인)
  rejected, // 심사 거절됨 (재신청 가능하도록 유도)
}

/// **Admission State**
///
/// Holds the calculated status and detailed reasons.
class AdmissionState {
  AdmissionState({
    required this.status,
    this.user,
    this.ineligibleReason,
    this.rejectionReason,
    this.missingVerificationIds = const [],
  });

  final EventAdmissionStatus status;
  final User? user;
  final String? ineligibleReason;
  final String? rejectionReason;
  final List<String> missingVerificationIds;
}

enum AdmissionButtonStyle {
  normal,
  disabled,
  destructive,
}

class AdmissionButtonConfig {
  const AdmissionButtonConfig({
    required this.label,
    this.enabled = true,
    this.style = AdmissionButtonStyle.normal,
  });

  final String label;
  final bool enabled;
  final AdmissionButtonStyle style;
}
