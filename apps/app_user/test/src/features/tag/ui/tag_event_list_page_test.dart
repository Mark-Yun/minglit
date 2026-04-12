// Ref #1335: TagEventListPage widget 테스트
//
// 검증 포인트:
// 1. 로딩 상태 → CircularProgressIndicator 렌더링
// 2. 빈 상태 → "아직 이 태그의 이벤트가 없어요" 메시지
// 3. 이벤트 목록 상태 → 이벤트 제목 렌더링
// 4. 에러 상태 → "이벤트를 불러오지 못했습니다" + "다시 시도"
// 5. AppBar 제목 — #tagName 형태
//
// 참고: eventCoordinatorProvider는 이벤트 탭 시에만 lazy 초기화되므로,
// 탭 없이 렌더링만 검증하는 테스트에서는 override 불필요.
import 'dart:async';

import 'package:app_user/src/features/tag/ui/tag_event_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

Event makeEvent(int index) => Event(
  id: 'event-$index',
  partyId: 'party-$index',
  title: 'Test Event $index',
  startTime: DateTime(2026, 5, index + 1),
  endTime: DateTime(2026, 5, index + 1, 2),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  const tagId = 'tag-001';
  const tagName = '클럽';

  late MockTagRepository mockTagRepo;

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        tagRepositoryProvider.overrideWithValue(mockTagRepo),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const TagEventListPage(tagId: tagId, tagName: tagName),
      ),
    );
  }

  setUp(() {
    mockTagRepo = MockTagRepository();
  });

  group('TagEventListPage', () {
    testWidgets(
      '로딩 상태 — CircularProgressIndicator가 렌더링된다',
      (tester) async {
        // Completer로 영원히 pending인 future를 만들어 loading 상태 유지
        when(
          () => mockTagRepo.getPartiesByTag(
            tagId,
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) => Completer<List<Event>>().future);

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      '빈 상태 — "아직 이 태그의 이벤트가 없어요" 메시지와 홈 버튼이 렌더링된다',
      (tester) async {
        when(
          () => mockTagRepo.getPartiesByTag(
            tagId,
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.text('아직 이 태그의 이벤트가 없어요'), findsOneWidget);
        expect(find.text('홈으로 돌아가기'), findsOneWidget);
      },
    );

    testWidgets(
      '이벤트 목록 상태 — 이벤트 제목이 렌더링된다',
      (tester) async {
        final events = [makeEvent(0), makeEvent(1)];
        when(
          () => mockTagRepo.getPartiesByTag(
            tagId,
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => events);

        await tester.pumpWidget(buildSubject());
        await tester.pump(); // provider 시작
        await tester.pump(); // AsyncData 완료 → 리빌드

        expect(find.text('Test Event 0'), findsOneWidget);
        expect(find.text('Test Event 1'), findsOneWidget);
      },
    );

    testWidgets(
      '에러 상태 — 에러 메시지와 "다시 시도" 버튼이 렌더링된다',
      (tester) async {
        // Fix #1335: Future.error()로 비동기 에러를 명시적으로 반환하여
        // Riverpod이 AsyncError state로 올바르게 전환하도록 한다.
        when(
          () => mockTagRepo.getPartiesByTag(
            tagId,
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) => Future.error(Exception('fetch failed'), StackTrace.empty),
        );

        await tester.pumpWidget(buildSubject());
        // error 케이스는 ListView 없으므로 pumpAndSettle 사용 가능
        await tester.pumpAndSettle();

        expect(find.text('이벤트를 불러오지 못했습니다'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
      },
    );

    testWidgets(
      'AppBar 제목 — #tagName 형태로 표시된다',
      (tester) async {
        when(
          () => mockTagRepo.getPartiesByTag(
            tagId,
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(buildSubject());
        await tester.pump();

        expect(find.text('#$tagName'), findsOneWidget);
      },
    );
  });
}
