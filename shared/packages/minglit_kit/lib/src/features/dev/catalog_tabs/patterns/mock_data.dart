// Mock data for design pattern catalog demos.
// Uses plain Dart types; no real Repository or model imports.

/// A mock event card data structure for demos.
class MockEventData {
  const MockEventData({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.locationLabel,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.hostName,
    required this.categoryLabel,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
  final String locationLabel;
  final int currentParticipants;
  final int maxParticipants;
  final String hostName;
  final String categoryLabel;
}

/// Sample events for pattern demos.
const mockEvents = [
  MockEventData(
    title: '재즈 이브닝 in 성수',
    subtitle: '재즈 음악을 사랑하는 분들을 위한 소셜 이벤트',
    dateLabel: '4월 15일 (화) 오후 7시',
    locationLabel: '성수 라이브 클럽, 서울',
    currentParticipants: 12,
    maxParticipants: 20,
    hostName: '밍글릿 팀',
    categoryLabel: '음악',
  ),
  MockEventData(
    title: '브런치 네트워킹',
    subtitle: '스타트업 종사자를 위한 캐주얼 모임',
    dateLabel: '4월 20일 (일) 오전 11시',
    locationLabel: '강남 카페 라떼, 서울',
    currentParticipants: 8,
    maxParticipants: 15,
    hostName: '스타트업 커뮤니티',
    categoryLabel: '네트워킹',
  ),
];

const mockSectionItems = [
  '이벤트 개요',
  '참여자 소개',
  '진행 일정',
  '준비물 안내',
  '위치 및 교통',
];
