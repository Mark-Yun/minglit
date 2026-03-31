import 'dart:async';

import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:app_user/src/features/consent/ui/consent_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Privacy settings page showing consent status, terms, and account
/// management.
class PrivacyPage extends ConsumerStatefulWidget {
  /// Creates a [PrivacyPage].
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  @override
  Widget build(BuildContext context) {
    final consentState = ref.watch(consentControllerProvider);
    final deletionStatus = ref.watch(accountDeletionControllerProvider);
    final isPending = deletionStatus.value?.isPending ?? false;

    ref.listen(consentControllerProvider, (prev, next) {
      if (next.hasError && (prev?.hasValue ?? false)) {
        // Fix #886: toggle 실패 시 원상복구 + 스낵바
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('동의 변경에 실패했습니다. 다시 시도해주세요.')),
        );
        // Invalidate to reload from server, which reverts the UI
        unawaited(
          Future.microtask(() {
            if (mounted) ref.invalidate(consentControllerProvider);
          }),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('개인정보')),
      body: consentState.when(
        loading: () =>
            const Center(child: MinglitCircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: Text(
              '동의 정보를 불러올 수 없습니다.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        data: (consents) {
          final consentMap = <ConsentType, bool>{
            for (final c in consents) c.consentKey: c.consented,
          };

          return ListView(
            children: [
              // — 동의 현황 —
              const _SectionHeader(title: '동의 현황'),
              _ReadOnlyConsentTile(
                title: '서비스 이용약관',
                onTap: () => showConsentDetailSheet(
                  context,
                  content: _termsOfServiceContent,
                ),
              ),
              _ReadOnlyConsentTile(
                title: '개인정보 수집·이용',
                onTap: () => showConsentDetailSheet(
                  context,
                  content: _privacyCollectionContent,
                ),
              ),
              SwitchListTile(
                title: const Text('제3자 제공 동의'),
                value: consentMap[ConsentType.thirdPartyProvision] ?? false,
                onChanged: (v) => _toggle(ConsentType.thirdPartyProvision, v),
              ),
              SwitchListTile(
                title: const Text('마케팅 정보 수신'),
                value: consentMap[ConsentType.marketingConsent] ?? false,
                onChanged: (v) => _toggle(ConsentType.marketingConsent, v),
              ),
              _ReadOnlyConsentTile(
                title: '본인인증 정보',
                statusText:
                    (consentMap[ConsentType.identityVerification] ?? false)
                        ? '동의됨'
                        : '미동의',
                onTap:
                    (consentMap[ConsentType.identityVerification] ?? false)
                        ? () => showConsentDetailSheet(
                          context,
                          content: _identityVerificationContent,
                        )
                    : null,
              ),

              const Divider(height: 1),

              // — 약관 보기 —
              const _SectionHeader(title: '약관 보기'),
              ListTile(
                title: const Text('서비스 이용약관'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showConsentDetailSheet(
                  context,
                  content: _termsOfServiceContent,
                ),
              ),
              ListTile(
                title: const Text('개인정보처리방침'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showConsentDetailSheet(
                  context,
                  content: _privacyPolicyContent,
                ),
              ),

              const Divider(height: 1),

              // — 계정 —
              const _SectionHeader(title: '계정'),
              Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: ListTile(
                  leading: Icon(
                    isPending
                        ? Icons.hourglass_top
                        : Icons.person_remove_outlined,
                    color: MinglitColors.error,
                  ),
                  title: Text(isPending ? '탈퇴 요청 진행 중' : '회원 탈퇴'),
                  subtitle: Text(
                    isPending
                        ? '유예 기간 안에는 다시 로그인해 계정을 복구할 수 있어요.'
                        : '탈퇴 사유 선택, 안내 확인, 본인 확인 후 요청할 수 있어요.',
                  ),
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    ref.read(accountDeletionCoordinatorProvider).start();
                  },
                  child: Text(isPending ? '탈퇴 진행 상태 보기' : '회원 탈퇴 시작하기'),
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggle(ConsentType type, bool value) async {
    await ref
        .read(consentControllerProvider.notifier)
        .toggleConsent(type, consented: value);
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.screenEdge,
        MinglitSpacing.large,
        MinglitSpacing.screenEdge,
        MinglitSpacing.small,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only consent tile (required consents + identity verification)
// ---------------------------------------------------------------------------

class _ReadOnlyConsentTile extends StatelessWidget {
  const _ReadOnlyConsentTile({
    required this.title,
    this.statusText = '동의됨',
    this.onTap,
  });

  final String title;
  final String statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Consent detail content (static data for bottom sheets)
// ---------------------------------------------------------------------------

const _termsOfServiceContent = ConsentDetailContent(
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
);

const _privacyCollectionContent = ConsentDetailContent(
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
);

const _identityVerificationContent = ConsentDetailContent(
  title: '본인인증(CI/DI) 수집 동의',
  summary: '본인 확인 서비스를 통해 연계정보(CI)와 중복가입확인정보(DI)를 수집합니다.',
  sections: [
    ConsentDetailSection(
      title: '수집 항목',
      items: [
        '연계정보(CI): 본인 확인을 위한 고유 식별값',
        '중복가입확인정보(DI): 동일 서비스 중복 가입 방지',
      ],
    ),
    ConsentDetailSection(
      title: '이용 목적',
      items: [
        '회원 본인 여부 확인',
        '중복 계정 생성 방지',
      ],
    ),
    ConsentDetailSection(
      title: '보관 기간',
      items: [
        '회원 탈퇴 시까지 보관하며, 탈퇴 후 즉시 파기합니다.',
      ],
    ),
  ],
);

const _privacyPolicyContent = ConsentDetailContent(
  title: '개인정보처리방침',
  summary: '밍릿의 개인정보 처리 방침을 안내합니다.',
  sections: [
    ConsentDetailSection(
      title: '수집하는 개인정보',
      items: [
        '회원가입: 이름, 이메일, 프로필 사진',
        '본인인증: 이름, 생년월일, 성별, 휴대폰 번호, CI/DI',
        '서비스 이용: 관심 태그, 이벤트 참여 기록, 기기 정보',
      ],
    ),
    ConsentDetailSection(
      title: '개인정보 이용 목적',
      items: [
        '회원 관리 및 서비스 제공',
        '이벤트 매칭 및 추천',
        '고객 문의 대응',
      ],
    ),
    ConsentDetailSection(
      title: '개인정보 보관 기간',
      items: [
        '회원 탈퇴 시까지 보관합니다.',
        '관련 법령에 따라 일정 기간 보관이 필요한 경우 해당 기간 동안 보관합니다.',
      ],
    ),
    ConsentDetailSection(
      title: '동의 철회',
      items: [
        '선택 항목은 설정 > 개인정보에서 언제든 철회할 수 있습니다.',
        '필수 항목은 회원 탈퇴로만 철회할 수 있습니다.',
      ],
    ),
  ],
);
