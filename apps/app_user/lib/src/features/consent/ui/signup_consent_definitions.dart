part of 'signup_consent_page.dart';

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
      // Fix #1143: PIPA 제22조 제4항 — 수집 항목·이용 목적·보관 기간 강조 의무
      sections: [
        ConsentDetailSection(
          title: '수집 항목',
          emphasized: true,
          items: ['이름, 이메일, 프로필 사진', '관심 태그, 이용 기록, 기기 정보'],
        ),
        ConsentDetailSection(
          title: '이용 목적',
          emphasized: true,
          items: ['회원 식별과 계정 관리', '이벤트 추천과 서비스 품질 개선', '고객 문의 대응과 공지 전달'],
        ),
        ConsentDetailSection(
          title: '보관 기간',
          emphasized: true,
          items: [
            // Fix #1182: PR #1161 정합성 — 탈퇴 후 즉시 파기 명시
            '회원 탈퇴 시까지 보관하며, 탈퇴 후 즉시 파기합니다.',
            '법령상 보관 의무가 있는 정보는 관련 기간 동안 별도 보관합니다.',
          ],
        ),
        ConsentDetailSection(
          title: '동의 거부 시 안내',
          emphasized: true,
          items: ['개인정보 수집·이용 동의를 거부하면 회원가입이 제한돼요.'],
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
  // Fix #1141: 제3자 제공 동의 항목 추가 — 성별 제외, 자격 인증 정보 포함, 보유기간 30일
  ConsentType.thirdPartyProvision: const _ConsentDefinition(
    type: ConsentType.thirdPartyProvision,
    title: '제3자 제공 동의',
    summary: '이벤트 주최 파트너에게 참가자 확인에 필요한 정보를 제공해요.',
    required: false,
    detail: ConsentDetailContent(
      title: '제3자 제공 동의',
      summary: '이벤트 운영을 위해 파트너에게 아래 정보를 제공합니다.',
      sections: [
        ConsentDetailSection(
          title: '제공받는 자',
          items: ['이벤트 주최 파트너 (신청한 이벤트의 해당 파트너에 한정)'],
        ),
        ConsentDetailSection(
          title: '제공 항목',
          items: ['이름(닉네임)', '연령대', '자격 인증 정보(직업/소속 — 본인인증 완료 유저만)'],
        ),
        ConsentDetailSection(
          title: '제공 목적',
          items: ['이벤트 운영 (참가자 확인, 매칭 진행, 체크인)'],
        ),
        ConsentDetailSection(title: '보유 기간', items: ['이벤트 종료 후 30일']),
        ConsentDetailSection(
          title: '거부 권리',
          items: [
            '동의를 거부할 수 있으며, 기본 서비스 이용은 가능합니다.',
            '다만 파트너 승인/확인이 필요한 이벤트는 신청 또는 참여가 제한될 수 있습니다.',
          ],
        ),
      ],
    ),
  ),
  ConsentType.locationConsent: const _ConsentDefinition(
    type: ConsentType.locationConsent,
    title: '위치정보 이용 동의',
    summary: '가까운 이벤트 추천을 위해 위치정보를 수집해요.',
    required: false,
    detail: ConsentDetailContent(
      title: '위치정보 이용 동의',
      summary: '위치기반서비스 이용을 위해 아래 내용을 안내합니다.',
      sections: [
        ConsentDetailSection(
          title: '수집 방법',
          emphasized: true,
          items: [
            'GPS, Wi-Fi, 기지국 정보를 통해 단말기의 위치를 수집합니다.',
            '위치정보는 앱 사용 중(foreground)에만 수집됩니다.',
          ],
        ),
        ConsentDetailSection(
          title: '이용 범위',
          emphasized: true,
          items: [
            '가까운 이벤트 검색 및 추천',
            '이벤트 장소까지의 거리 정보 제공',
          ],
        ),
        ConsentDetailSection(
          title: '보유 기간',
          emphasized: true,
          items: [
            '위치정보는 서비스 제공 목적 달성 후 즉시 파기합니다.',
            '별도 저장하지 않으며, 일회성으로만 이용됩니다.',
          ],
        ),
        ConsentDetailSection(
          title: '동의 거부 시 안내',
          emphasized: true,
          items: [
            '위치정보 동의를 거부해도 서비스 이용이 가능해요.',
            '다만 가까운 이벤트 검색 등 위치 기반 기능이 제한될 수 있어요.',
          ],
        ),
      ],
    ),
  ),
  ConsentType.identityVerification: const _ConsentDefinition(
    type: ConsentType.identityVerification,
    title: '본인인증(CI/DI) 수집 동의',
    summary: '본인 확인을 위해 CI/DI 정보를 수집해요.',
    required: false,
    detail: ConsentDetailContent(
      title: '본인인증(CI/DI) 수집 동의',
      summary: '본인 확인 서비스를 통해 연계정보(CI)와 중복가입확인정보(DI)를 수집합니다.',
      // Fix #1143: PIPA 제22조 제4항 — CI/DI 수집 항목·보관 기간 강조 의무
      sections: [
        ConsentDetailSection(
          title: '수집 항목',
          emphasized: true,
          items: [
            '연계정보(CI): 본인 확인을 위한 고유 식별값',
            '중복가입확인정보(DI): 동일 서비스 중복 가입 방지',
          ],
        ),
        ConsentDetailSection(
          title: '이용 목적',
          items: ['회원 본인 여부 확인', '중복 계정 생성 방지'],
        ),
        ConsentDetailSection(
          title: '보관 기간',
          emphasized: true,
          items: ['회원 탈퇴 시까지 보관하며, 탈퇴 후 즉시 파기합니다.'],
        ),
        ConsentDetailSection(
          title: '동의 거부 시 안내',
          emphasized: true,
          items: ['본인인증 동의를 거부해도 서비스 이용이 가능해요. 단, 본인인증이 필요한 일부 기능이 제한될 수 있어요.'],
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
        ConsentDetailSection(title: '수신 채널', items: ['푸시 알림', '이메일']),
        ConsentDetailSection(
          title: '안내 내용',
          items: ['추천 이벤트와 프로모션', '서비스 업데이트와 혜택 정보'],
        ),
      ],
    ),
  ),
};
