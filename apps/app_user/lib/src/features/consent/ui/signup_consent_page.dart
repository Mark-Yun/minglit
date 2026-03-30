import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/consent_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

const _signupPolicyVersion = 1;

class SignupConsentPage extends ConsumerStatefulWidget {
  const SignupConsentPage({
    super.key,
    this.from,
  });

  final String? from;

  @override
  ConsumerState<SignupConsentPage> createState() => _SignupConsentPageState();
}

class _SignupConsentPageState extends ConsumerState<SignupConsentPage> {
  final Set<ConsentType> _selectedConsents = <ConsentType>{};
  bool _didHydrate = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(consentControllerProvider, (_, next) {
      next.showMinglitError(context);

      if (_didHydrate || !next.hasValue) return;

      final selected = next.requireValue
          .where((consent) => consent.consented)
          .map((consent) => consent.consentKey)
          .where(_consentDefinitions.containsKey)
          .toSet();

      setState(() {
        _selectedConsents
          ..clear()
          ..addAll(selected);
        _didHydrate = true;
      });
    });

    final consentState = ref.watch(consentControllerProvider);
    final isInitialLoading =
        !_didHydrate && consentState.isLoading && !consentState.hasError;
    final allSelected = _selectedConsents.length == _consentDefinitions.length;
    final requiredSelected = ConsentType.requiredTypes.every(
      _selectedConsents.contains,
    );

    if (isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: MinglitCircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        bottomNavigationBar: MinglitBottomCTA(
          label: '다 같이 시작하기',
          enabled: requiredSelected && !_isSubmitting,
          onPressed: requiredSelected && !_isSubmitting ? _submit : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MinglitSpacing.large,
                    MinglitSpacing.xlarge,
                    MinglitSpacing.large,
                    MinglitSpacing.large,
                  ),
                  children: [
                    Text(
                      '환영합니다!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    Text(
                      '밍릿 이용을 시작하기 전에 꼭 필요한 약관을 확인해주세요.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xlarge),
                    Card(
                      child: SwitchListTile(
                        value: allSelected,
                        onChanged: _toggleAll,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: MinglitSpacing.medium,
                          vertical: MinglitSpacing.xsmall,
                        ),
                        title: const Text('전체 동의'),
                        subtitle: const Text(
                          '필수와 선택 약관을 한 번에 설정할 수 있어요.',
                        ),
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    for (final definition in _consentDefinitions.values) ...[
                      _ConsentItemTile(
                        definition: definition,
                        selected: _selectedConsents.contains(definition.type),
                        onChanged: (selected) =>
                            _toggleSingle(definition.type, selected),
                        onShowDetail: definition.detail == null
                            ? null
                            : () => showConsentDetailSheet(
                                context,
                                content: definition.detail!,
                              ),
                      ),
                      const SizedBox(height: MinglitSpacing.small),
                    ],
                    const SizedBox(height: MinglitSpacing.small),
                    Text(
                      '선택 항목 미동의 시에도 서비스 이용이 가능합니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_isSubmitting) ...[
                      const SizedBox(height: MinglitSpacing.medium),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: MinglitSpacing.small),
                          Text(
                            '동의 내용을 저장하고 있어요.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedConsents
          ..clear()
          ..addAll(_consentDefinitions.keys);
      } else {
        _selectedConsents.clear();
      }
    });
  }

  void _toggleSingle(ConsentType type, bool selected) {
    setState(() {
      if (selected) {
        _selectedConsents.add(type);
      } else {
        _selectedConsents.remove(type);
      }
    });
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.showMinglitWarning('로그인이 필요합니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    await ref
        .read(consentControllerProvider.notifier)
        .saveSignupConsents(
          _selectedConsents.toList(),
          policyVersion: _signupPolicyVersion,
        );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    final state = ref.read(consentControllerProvider);
    if (state.hasError) return;

    ref.read(consentCoordinatorProvider).completeSignup(from: widget.from);
  }
}

class _ConsentItemTile extends StatelessWidget {
  const _ConsentItemTile({
    required this.definition,
    required this.selected,
    required this.onChanged,
    this.onShowDetail,
  });

  final _ConsentDefinition definition;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onShowDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        onTap: () => onChanged(!selected),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: MinglitSpacing.xsmall),
                  child: Checkbox(
                    value: selected,
                    onChanged: (value) => onChanged(value ?? false),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ConsentTag(required: definition.required),
                          const SizedBox(width: MinglitSpacing.xsmall),
                          Expanded(
                            child: Text(
                              definition.title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MinglitSpacing.xsmall),
                      Text(
                        definition.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onShowDetail != null) ...[
                  const SizedBox(width: MinglitSpacing.small),
                  TextButton(
                    onPressed: onShowDetail,
                    child: const Text('보기'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentTag extends StatelessWidget {
  const _ConsentTag({
    required this.required,
  });

  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = required
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final background = required
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.xsmall,
          vertical: 4,
        ),
        child: Text(
          required ? '필수' : '선택',
          style: theme.textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _ConsentDefinition {
  const _ConsentDefinition({
    required this.type,
    required this.title,
    required this.summary,
    required this.required,
    this.detail,
  });

  final ConsentType type;
  final String title;
  final String summary;
  final bool required;
  final ConsentDetailContent? detail;
}

final Map<ConsentType, _ConsentDefinition> _consentDefinitions = {
  ConsentType.termsOfService: const _ConsentDefinition(
    type: ConsentType.termsOfService,
    title: '서비스 이용약관',
    summary: '계정 생성과 서비스 이용을 위한 기본 약관이에요.',
    required: true,
    detail: ConsentDetailContent(
      title: '서비스 이용약관',
      summary: '서비스 이용을 위해 필요한 기본 권리와 의무를 안내합니다.',
      sections: [
        ConsentDetailSection(
          title: '주요 내용',
          items: [
            '회원은 정확한 정보를 제공하고 안전하게 계정을 관리해야 합니다.',
            '서비스 운영 정책과 커뮤니티 가이드를 위반하면 이용이 제한될 수 있습니다.',
            '결제, 환불, 이벤트 신청 등 세부 정책은 개별 안내와 함께 적용됩니다.',
          ],
        ),
        ConsentDetailSection(
          title: '이용자 보호',
          items: [
            '법령과 약관에 따라 개인정보와 거래 정보를 보호합니다.',
            '문의와 분쟁은 고객 지원 채널을 통해 접수하고 순차적으로 처리합니다.',
          ],
        ),
      ],
    ),
  ),
  ConsentType.privacyCollection: const _ConsentDefinition(
    type: ConsentType.privacyCollection,
    title: '개인정보 수집·이용 동의',
    summary: '회원가입과 맞춤형 서비스 제공에 필요한 정보를 수집해요.',
    required: true,
    detail: ConsentDetailContent(
      title: '개인정보 수집·이용 동의',
      summary: '수집 항목과 이용 목적, 보관 기간을 안내합니다.',
      sections: [
        ConsentDetailSection(
          title: '수집 항목',
          items: [
            '이름, 이메일, 프로필 사진',
            '관심 태그, 이용 기록, 기기 정보',
          ],
        ),
        ConsentDetailSection(
          title: '이용 목적',
          items: [
            '회원 식별과 계정 관리',
            '이벤트 추천과 서비스 품질 개선',
            '고객 문의 대응과 공지 전달',
          ],
        ),
        ConsentDetailSection(
          title: '보관 기간',
          items: [
            '회원 탈퇴 시까지 보관합니다.',
            '법령상 보관 의무가 있는 정보는 관련 기간 동안 별도 보관합니다.',
          ],
        ),
      ],
    ),
  ),
  ConsentType.ageConfirmation: const _ConsentDefinition(
    type: ConsentType.ageConfirmation,
    title: '만 14세 이상 확인',
    summary: '만 14세 이상만 회원가입할 수 있어요.',
    required: true,
  ),
  ConsentType.thirdPartyProvision: const _ConsentDefinition(
    type: ConsentType.thirdPartyProvision,
    title: '제3자 제공 동의',
    summary: '이벤트 운영에 필요한 정보를 파트너에게 전달할 수 있어요.',
    required: false,
    detail: ConsentDetailContent(
      title: '제3자 제공 동의',
      summary: '이벤트 신청과 운영을 위해 필요한 범위에서만 정보를 제공합니다.',
      sections: [
        ConsentDetailSection(
          title: '제공 대상',
          items: [
            '이벤트를 운영하는 주최 파트너',
          ],
        ),
        ConsentDetailSection(
          title: '제공 정보',
          items: [
            '이름, 성별, 연령대',
          ],
        ),
        ConsentDetailSection(
          title: '목적과 보관 기간',
          items: [
            '이벤트 운영과 참석자 확인을 위해 사용합니다.',
            '이벤트 종료 후 30일 이내 파기합니다.',
          ],
        ),
      ],
    ),
  ),
  ConsentType.marketingConsent: const _ConsentDefinition(
    type: ConsentType.marketingConsent,
    title: '마케팅 정보 수신 동의',
    summary: '새 이벤트와 혜택 소식을 푸시나 이메일로 받아볼 수 있어요.',
    required: false,
    detail: ConsentDetailContent(
      title: '마케팅 정보 수신 동의',
      summary: '선택 동의이며, 언제든 설정에서 변경할 수 있습니다.',
      sections: [
        ConsentDetailSection(
          title: '수신 채널',
          items: [
            '푸시 알림',
            '이메일',
          ],
        ),
        ConsentDetailSection(
          title: '안내 내용',
          items: [
            '추천 이벤트와 프로모션',
            '서비스 업데이트와 혜택 정보',
          ],
        ),
      ],
    ),
  ),
};
