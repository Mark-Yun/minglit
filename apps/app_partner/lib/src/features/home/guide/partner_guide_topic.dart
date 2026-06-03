import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerGuideTopic {
  const PartnerGuideTopic({
    required this.slug,
    required this.routePath,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String slug;
  final String routePath;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<HelpSection> sections;
}

const partnerGuideTopics = [
  PartnerGuideTopic(
    slug: 'dashboard-overview',
    routePath: '/guide/dashboard/overview',
    icon: Icons.query_stats_outlined,
    iconColor: MinglitColors.info,
    title: '운영 현황',
    subtitle: '대시보드 숫자와 이동 경로',
    sections: [
      HelpSection(
        title: '이 숫자가 뭔가요?',
        body:
            '등록된 파티는 게시 완료된 파티 수예요. '
            '모집 중인 이벤트는 활성 이벤트 수이고, '
            '참가예정 고객은 활성 이벤트의 결제 완료 참가자 합계예요.',
      ),
      HelpSection(
        title: '탭하면 어디로 이동하나요?',
        body: '등록된 파티는 파티 리스트, 모집 중인 이벤트는 이벤트 리스트, 참가예정 고객은 신청관리 탭으로 이동해요.',
      ),
    ],
  ),
  PartnerGuideTopic(
    slug: 'operations-live',
    routePath: '/guide/operations/live',
    icon: Icons.play_circle_outline,
    iconColor: MinglitColors.success,
    title: '진행 중',
    subtitle: '체크인과 이벤트 운영',
    sections: [
      HelpSection(
        title: '체크인은 언제부터 가능한가요?',
        body:
            '이벤트 시작 2시간 전부터 QR 체크인이 활성화돼요. '
            '그 전에는 QR 체크인 버튼이 비활성 상태로 보여요.',
      ),
      HelpSection(
        title: 'QR 체크인과 수동 체크인은 어떻게 다른가요?',
        body:
            'QR 체크인은 사용자가 보여준 QR을 스캔하는 기본 흐름이에요. '
            'QR을 읽기 어렵거나 휴대폰 분실 같은 예외 상황에서는 '
            '명단에서 수동 체크인을 사용할 수 있어요.',
      ),
      HelpSection(
        title: '이벤트가 끝나면 어떻게 되나요?',
        body:
            '종료 시각 이후 24시간 동안 홈에 남아 운영 상태를 확인할 수 있고, '
            '이후에는 홈에서 사라져요. 정산 탭에서는 계속 추적할 수 있어요.',
      ),
    ],
  ),
  PartnerGuideTopic(
    slug: 'applications-pending',
    routePath: '/guide/applications/pending',
    icon: Icons.fact_check_outlined,
    iconColor: MinglitColors.primary,
    title: '이벤트 참가 승인 대기',
    subtitle: '승인, 거절, 결제 전환',
    sections: [
      HelpSection(
        title: '왜 승인이 필요한가요?',
        body: '파트너가 사용자 프로필, 사진, 자기소개를 확인한 뒤 승인해야 결제 안내가 발송되고 참가가 확정돼요.',
      ),
      HelpSection(
        title: '거절하면 환불이 필요한가요?',
        body: '거절 단계에서는 결제가 진행되지 않으므로 환불이 필요하지 않아요. 입력한 거절 사유는 사용자에게 안내돼요.',
      ),
      HelpSection(
        title: '승인 후 사용자가 결제하지 않으면요?',
        body: '승인 후 24시간 안에 결제가 완료되지 않으면 신청이 자동 만료돼요.',
      ),
    ],
  ),
  PartnerGuideTopic(
    slug: 'operations-upcoming',
    routePath: '/guide/operations/upcoming',
    icon: Icons.event_available_outlined,
    iconColor: MinglitColors.warning,
    title: '진행 임박',
    subtitle: 'T-7 체크리스트와 환불 정책',
    sections: [
      HelpSection(
        title: '진행 임박은 어떤 상태인가요?',
        body: '시작 7일 이내 이벤트예요. 최종 명단 확인, 워크인 준비, 환불 정책 확인이 필요한 단계예요.',
      ),
      HelpSection(
        title: '환불 정책은 어떻게 적용되나요?',
        body: 'T-7 이내 사용자 환불 요청은 정책에 따라 부분 환불될 수 있어요. 파트너 사유 취소는 전액 환불로 처리돼요.',
      ),
      HelpSection(
        title: '정산 기준은 무엇인가요?',
        body: 'QR 체크인 완료 참가자가 정산 기준이에요. 정산 마감일은 이벤트 종료 후 익월 말일이에요.',
      ),
    ],
  ),
  PartnerGuideTopic(
    slug: 'events-recruiting',
    routePath: '/guide/events/recruiting',
    icon: Icons.campaign_outlined,
    iconColor: MinglitColors.tertiary,
    title: '모집 중인 이벤트',
    subtitle: '공유, 정원, 가격 변경',
    sections: [
      HelpSection(
        title: '이벤트는 어떻게 공유하나요?',
        body:
            '이벤트 상세 화면의 공유 버튼을 사용해요. '
            '앱을 설치하지 않은 사용자도 웹 미리보기로 내용을 확인할 수 있어요.',
      ),
      HelpSection(
        title: '정원이 다 차지 않아도 진행할 수 있나요?',
        body: '최소 인원을 별도로 설정하지 않았다면 정원 미달이어도 진행할 수 있어요.',
      ),
      HelpSection(
        title: '모집 시작 후 가격 변경이 가능한가요?',
        body:
            '이미 결제한 사용자가 있을 수 있어 모집 시작 후 가격 변경은 지원하지 않아요. '
            '변경이 필요하면 이벤트를 취소하고 다시 생성해야 해요.',
      ),
    ],
  ),
  PartnerGuideTopic(
    slug: 'create-party-drafts',
    routePath: '/guide/create-party/drafts',
    icon: Icons.edit_calendar_outlined,
    iconColor: MinglitColors.secondary,
    title: '작성 중인 파티',
    subtitle: '임시저장, 게시, 이벤트 연결',
    sections: [
      HelpSection(
        title: '임시저장과 게시는 어떻게 다른가요?',
        body: '임시저장은 사용자에게 노출되지 않아요. 게시하면 검색에 노출되지만, 사용자가 신청하려면 이벤트를 만들어야 해요.',
      ),
      HelpSection(
        title: '파티와 이벤트는 무엇이 다른가요?',
        body: '파티는 모임의 브랜드이고 이벤트는 회차예요. 하나의 파티 안에서 여러 이벤트를 반복 운영할 수 있어요.',
      ),
      HelpSection(
        title: '이미지는 어떤 규격이 좋나요?',
        body: '16:9 비율, 최소 1080x608, JPG 또는 PNG를 권장해요. 사용자 앱의 대표 영역에 노출돼요.',
      ),
    ],
  ),
];

PartnerGuideTopic? partnerGuideTopicBySlug(String slug) {
  for (final topic in partnerGuideTopics) {
    if (topic.slug == slug) {
      return topic;
    }
  }
  return null;
}

Future<void> showPartnerGuideTopicSheet(
  BuildContext context,
  PartnerGuideTopic topic,
) {
  return showMinglitHelpSheet(
    context: context,
    title: topic.title,
    sections: topic.sections,
  );
}
