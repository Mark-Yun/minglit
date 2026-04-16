// Ref #1335: IT-U14 태그 탐색 CUJ 통합 테스트
//
// 검증 포인트:
// TC-U14-001: TagEventListRoute → TagEventListPage 렌더링 + 이벤트 표시
// TC-U14-002: 태그 이벤트 빈 상태 → "아직 이 태그의 이벤트가 없어요"
//
// 테스트 전략:
// - TagEventListRoute를 initialLocation으로 사용하여 GoRouter 네비게이션을 통한
//   TagEventListPage 렌더링을 검증한다.
// - FeaturedTagChipBar 칩 탭 → 라우터 push → TagEventListPage 도달 경로는
//   featured_tag_chip_bar_test.dart의 탭 테스트로 커버된다.
import 'package:app_user/src/features/tag/ui/tag_event_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/golden_capture.dart';
import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late MockTagRepository mockTagRepo;

  Event makeEvent(int i) => Event(
    id: 'event-$i',
    partyId: 'party-$i',
    title: '태그 이벤트 $i',
    startTime: DateTime(2026, 5, i + 1),
    endTime: DateTime(2026, 5, i + 1, 2),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    mockTagRepo = MockTagRepository();
    // 기본: 모든 태그 요청에 빈 목록
    when(
      () => mockTagRepo.getFeaturedTags(),
    ).thenAnswer((_) async => []);
    when(
      () => mockTagRepo.getTrendingTags(),
    ).thenAnswer((_) async => []);
    when(
      () => mockTagRepo.getPartiesByTag(
        any(),
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);
  });

  group('IT-U14 태그 탐색 CUJ', () {
    final capture = GoldenCapture('cuj_u12');

    // TC-U14-001: TagEventListRoute → TagEventListPage + 이벤트 렌더링
    testWidgets(
      'TC-U14-001: TagEventListRoute 진입 시 TagEventListPage가 렌더링되고 이벤트 목록이 표시된다',
      (tester) async {
        setKoreanLocale(tester);

        final events = [makeEvent(0), makeEvent(1)];
        when(
          () => mockTagRepo.getPartiesByTag(
            'tag-001',
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await tester.pumpWidget(
          createTestApp(
            initialLocation: '/tags/tag-001?tag-name=클럽',
            additionalOverrides: [
              tagRepositoryProvider.overrideWithValue(mockTagRepo),
            ],
          ),
        );
        await tester.pump(); // GoRouter 라우팅 완료
        await tester.pump(); // provider 시작
        await tester.pump(); // AsyncData 완료 → 리빌드

        await capture.setup(tester, 0);

        expect(find.byType(TagEventListPage), findsOneWidget);
        expect(find.text('#클럽'), findsOneWidget); // AppBar title
        expect(find.text('태그 이벤트 0'), findsOneWidget);
        expect(find.text('태그 이벤트 1'), findsOneWidget);
      },
    );

    // TC-U14-002: 태그 이벤트 빈 상태
    testWidgets(
      'TC-U14-002: 태그에 이벤트가 없으면 "아직 이 태그의 이벤트가 없어요" 메시지가 표시된다',
      (tester) async {
        setKoreanLocale(tester);

        // mockTagRepo는 기본으로 빈 목록 반환 (setUp에서 설정)
        await tester.pumpWidget(
          createTestApp(
            initialLocation: '/tags/tag-002?tag-name=독서',
            additionalOverrides: [
              tagRepositoryProvider.overrideWithValue(mockTagRepo),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();

        await capture.after(tester, 1);

        expect(find.byType(TagEventListPage), findsOneWidget);
        expect(find.text('아직 이 태그의 이벤트가 없어요'), findsOneWidget);
        expect(find.text('홈으로 돌아가기'), findsOneWidget);
      },
    );
  });
}
