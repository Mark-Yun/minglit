import 'package:minglit_kit/minglit_kit.dart';

class AccountDeletionReasonOption {
  const AccountDeletionReasonOption({
    required this.code,
    required this.title,
    required this.description,
  });

  final WithdrawalReasonCode code;
  final String title;
  final String description;
}

const accountDeletionReasonOptions = <AccountDeletionReasonOption>[
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.noLongerUse,
    title: '더 이상 운영하지 않아요',
    description: '파트너 앱이나 밍릿 운영이 지금은 필요하지 않아요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.noDesiredEvents,
    title: '원하는 운영 환경이 아니에요',
    description: '원하는 고객층이나 이벤트 운영 방식과 맞지 않았어요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.usingOtherService,
    title: '다른 서비스를 이용 중이에요',
    description: '운영 관리에 다른 서비스를 더 자주 사용하고 있어요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.privacyConcern,
    title: '정보 보관이 걱정돼요',
    description: '사업자/정산 정보 보관이 걱정돼요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.poorUsability,
    title: '앱 사용이 어려워요',
    description: '원하는 기능을 찾거나 운영 흐름을 쓰기 어려웠어요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.other,
    title: '직접 입력할게요',
    description: '자유롭게 이유를 남길 수 있어요.',
  ),
];

WithdrawalReasonCode? parseWithdrawalReasonCode(String? value) {
  switch (value) {
    case 'no_longer_use':
      return WithdrawalReasonCode.noLongerUse;
    case 'no_desired_events':
      return WithdrawalReasonCode.noDesiredEvents;
    case 'using_other_service':
      return WithdrawalReasonCode.usingOtherService;
    case 'privacy_concern':
      return WithdrawalReasonCode.privacyConcern;
    case 'poor_usability':
      return WithdrawalReasonCode.poorUsability;
    case 'other':
      return WithdrawalReasonCode.other;
    default:
      return null;
  }
}

String encodeWithdrawalReasonCode(WithdrawalReasonCode code) {
  switch (code) {
    case WithdrawalReasonCode.noLongerUse:
      return 'no_longer_use';
    case WithdrawalReasonCode.noDesiredEvents:
      return 'no_desired_events';
    case WithdrawalReasonCode.usingOtherService:
      return 'using_other_service';
    case WithdrawalReasonCode.privacyConcern:
      return 'privacy_concern';
    case WithdrawalReasonCode.poorUsability:
      return 'poor_usability';
    case WithdrawalReasonCode.other:
      return 'other';
  }
}

String withdrawalReasonLabel(WithdrawalReasonCode code) {
  return accountDeletionReasonOptions
      .firstWhere((option) => option.code == code)
      .title;
}

WithdrawalReason? buildWithdrawalReason({
  String? reasonCode,
  String? reasonText,
}) {
  final parsedCode = parseWithdrawalReasonCode(reasonCode);
  return buildWithdrawalReasonFromCode(
    reasonCode: parsedCode,
    reasonText: reasonText,
  );
}

WithdrawalReason? buildWithdrawalReasonFromCode({
  WithdrawalReasonCode? reasonCode,
  String? reasonText,
}) {
  if (reasonCode == null) return null;

  final trimmedReason = reasonText?.trim();
  return WithdrawalReason(
    reasonCode: reasonCode,
    detail: trimmedReason == null || trimmedReason.isEmpty
        ? null
        : trimmedReason,
  );
}

bool usesPasswordAuth(User user) {
  return hasPasswordCredential(user);
}
