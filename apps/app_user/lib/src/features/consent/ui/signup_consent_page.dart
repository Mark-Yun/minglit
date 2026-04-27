import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/consent_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'signup_consent_widgets.dart';
part 'signup_consent_definitions.dart';

const _signupPolicyVersion = 1;

class SignupConsentPage extends ConsumerStatefulWidget {
  const SignupConsentPage({super.key, this.from});

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
        body: Center(child: MinglitCircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        // Fix #966: CTA 레이블 "동의하고 시작하기"로 수정 (UX 리뷰 반영)
        bottomNavigationBar: MinglitBottomCTA(
          label: '동의하고 시작하기',
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
                    // Fix #966: SwitchListTile → 원형 체크박스 + primary tint 배경
                    _AllConsentTile(
                      allSelected: allSelected,
                      onToggle: _toggleAll,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    // Fix #966: 개별 Card 제거 → 단일 Card 내 flat list
                    Card(
                      child: Column(
                        children: [
                          for (final (index, definition)
                              in _consentDefinitions.values.indexed) ...[
                            _ConsentItemTile(
                              definition: definition,
                              selected: _selectedConsents.contains(
                                definition.type,
                              ),
                              onChanged: (selected) =>
                                  _toggleSingle(definition.type, selected),
                              onShowDetail: definition.detail == null
                                  ? null
                                  : () => showConsentDetailSheet(
                                      context,
                                      content: definition.detail!,
                                    ),
                            ),
                            // Fix #966: 필수/선택 구분선 — 현재 항목이 필수이고
                            // 다음 항목이 선택이거나 마지막일 때 표시.
                            // requiredTypes.last에 의존하지 않으므로 항목 추가 시에도 안전.
                            if (definition.required &&
                                (index == _consentDefinitions.length - 1 ||
                                    !_consentDefinitions.values
                                        .elementAt(index + 1)
                                        .required))
                              const Divider(
                                height: 1,
                                indent: MinglitSpacing.medium,
                                endIndent: MinglitSpacing.medium,
                              ),
                          ],
                        ],
                      ),
                    ),
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
