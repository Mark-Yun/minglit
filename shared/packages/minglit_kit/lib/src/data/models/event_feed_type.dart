/// **Event Feed Type**
///
/// Defines different curation types for event lists.
enum EventFeedType {
  /// Nearest events based on user location.
  nearest('내 주변 파티', '거리순'),

  /// Newly created events.
  newArrivals('신규 오픈', '최신순'),

  /// Events that are closing recruitment soon.
  closingSoon('마감 임박', '마감순'),

  /// Early bird special offers.
  earlyBird('얼리버드 특가', '가격순'),

  /// AI-powered personalized recommendations.
  aiRecommended('AI 추천', '추천순');

  const EventFeedType(this.title, this.sortLabel);

  /// Display title for this feed type.
  final String title;

  /// Sort label used for UI descriptions.
  final String sortLabel;
}
