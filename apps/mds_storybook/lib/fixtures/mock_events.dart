// Storybook-only fixture data — plain Dart types, no minglit_kit domain models.
// Extracted from the deleted minglit_kit catalog_tabs/patterns/mock_data.dart.

/// A lightweight event data holder for storybook stories.
class MockEvent {
  const MockEvent({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.locationLabel,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.categoryLabel,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
  final String locationLabel;
  final int currentParticipants;
  final int maxParticipants;
  final String categoryLabel;
}

const sampleEvents = [
  MockEvent(
    title: '재즈 이브닝 in 성수',
    subtitle: '재즈 음악을 사랑하는 분들을 위한 소셜 이벤트',
    dateLabel: '4월 15일 (화) 오후 7시',
    locationLabel: '성수 라이브 클럽, 서울',
    currentParticipants: 12,
    maxParticipants: 20,
    categoryLabel: '음악',
  ),
  MockEvent(
    title: '브런치 네트워킹',
    subtitle: '스타트업 종사자를 위한 캐주얼 모임',
    dateLabel: '4월 20일 (일) 오전 11시',
    locationLabel: '강남 카페 라떼, 서울',
    currentParticipants: 8,
    maxParticipants: 15,
    categoryLabel: '네트워킹',
  ),
];
