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
    title: '더 이상 쓰지 않아요',
    description: '밍릿이 현재 필요하지 않아요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.noDesiredEvents,
    title: '원하는 이벤트가 없어요',
    description: '찾고 싶은 분위기나 주제의 이벤트가 부족했어요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.usingOtherService,
    title: '다른 서비스를 이용 중이에요',
    description: '비슷한 목적의 다른 서비스를 더 자주 사용해요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.privacyConcern,
    title: '개인정보가 걱정돼요',
    description: '계정과 개인정보 보관이 걱정돼요.',
  ),
  AccountDeletionReasonOption(
    code: WithdrawalReasonCode.poorUsability,
    title: '앱 사용이 어려워요',
    description: '원하는 기능을 찾거나 사용하는 과정이 복잡했어요.',
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
  if (parsedCode == null) return null;

  final trimmedReason = reasonText?.trim();
  return WithdrawalReason(
    reasonCode: parsedCode,
    detail: trimmedReason == null || trimmedReason.isEmpty
        ? null
        : trimmedReason,
  );
}

bool usesPasswordAuth(User user) {
  final identities = user.identities ?? const [];
  if (identities.any((identity) => identity.provider == 'email')) {
    return true;
  }

  final provider = user.appMetadata['provider'];
  if (provider == 'email') {
    return true;
  }

  final providers = user.appMetadata['providers'];
  if (providers is List) {
    return providers.contains('email');
  }

  return false;
}
