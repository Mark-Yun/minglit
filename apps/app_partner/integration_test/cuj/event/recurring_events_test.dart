// CUJ tests — event / recurring-events
//
// 대응 spec: docs/features/event/recurring-events/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 1-1, 1-2, 1-3, 1-4 (반복 설정 + 저장/생성 호출 계약)
//   - CUJ 2-1, 2-2, 2-3 (개별 회차 진입/분리 + 반복 아이콘 표시)
//   - CUJ 3-1, 3-2, 3-3, 3-4 (반복 규칙 관리 화면 — 일시정지/재개/수정/취소)
//   - CUJ 4-1, 4-2 (크론 상태 관찰 정보 + 실패 후 재시도 경로 계약)
//
// 설계 결정:
//   - RecurrenceSettingsSection: 자체 내부 provider — override 불필요.
//   - RecurrenceManagementScreen: partyRecurrenceRuleProvider override 로 격리.
//   - EventCreate 저장 동작은 controller.submit() 호출 계약만 검증 (UI submit 동선은
//     event-create CUJ에서 별도 검증).

import 'dart:async' show FutureOr;

import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/tabs/party_event_management_tab.dart';
import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:app_partner/src/features/party/recurrence/recurrence_management_controller.dart';
import 'package:app_partner/src/features/party/recurrence/recurrence_management_screen.dart';
import 'package:app_partner/src/features/party/ui/recurrence_settings_section.dart';
import 'package:app_partner/src/features/party/widgets/recurrence_rule_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockRecurrenceRuleRepository extends Mock
    implements RecurrenceRuleRepository {}

class _MockPartyRepository extends Mock implements PartyRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

class _MockPartyDetailCoordinator extends Mock
    implements PartyDetailCoordinator {}

// ---------------------------------------------------------------------------
// Fake providers
// ---------------------------------------------------------------------------

/// 반복 규칙 없음을 반환하는 가짜 컨트롤러 (UI 초기 상태 테스트용).
class _FakeNoRuleController extends RecurrenceManagementController {
  @override
  FutureOr<void> build() {}
}

class _EnabledRecurrenceSettingsController
    extends RecurrenceSettingsController {
  @override
  RecurrenceSettingsState build() => const RecurrenceSettingsState(
    isEnabled: true,
    daysOfWeek: [1, 3],
  );
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

final _epoch = DateTime(2020);

RecurrenceRule _makeRule({
  String id = 'rule-1',
  String partyId = 'party-1',
  RecurrencePattern pattern = RecurrencePattern.weekly,
  RecurrenceStatus status = RecurrenceStatus.active,
  List<int> daysOfWeek = const [1],
  String? endDate,
  String? lastGeneratedDate,
}) => RecurrenceRule(
  id: id,
  partyId: partyId,
  pattern: pattern,
  startTime: '20:00',
  endTime: '22:00',
  createdAt: _epoch,
  updatedAt: _epoch,
  status: status,
  daysOfWeek: daysOfWeek,
  endDate: endDate,
  lastGeneratedDate: lastGeneratedDate,
);

Party _makeParty({
  String id = 'party-1',
  String partnerId = 'partner-1',
  String title = '테스트 파티',
}) => Party(
  id: id,
  partnerId: partnerId,
  title: title,
  createdAt: _epoch,
  updatedAt: _epoch,
);

Event _makeEvent({
  String id = 'event-1',
  String partyId = 'party-1',
  String title = '1회차',
  String status = 'scheduled',
}) {
  final start = DateTime.now().add(const Duration(days: 7));
  return Event(
    id: id,
    partyId: partyId,
    title: title,
    status: status,
    startTime: start,
    endTime: start.add(const Duration(hours: 2)),
    createdAt: _epoch,
    updatedAt: _epoch,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockRecurrenceRuleRepository mockRepo;
  late _MockPartyRepository mockPartyRepo;
  late _MockLocationRepository mockLocationRepo;
  late _MockPartyDetailCoordinator mockPartyDetailCoordinator;

  setUpAll(() {
    registerFallbackValue(_makeEvent());
    registerFallbackValue(RecurrencePattern.weekly);
    registerFallbackValue(<int>[1]);
  });

  setUp(() {
    mockRepo = _MockRecurrenceRuleRepository();
    mockPartyRepo = _MockPartyRepository();
    mockLocationRepo = _MockLocationRepository();
    mockPartyDetailCoordinator = _MockPartyDetailCoordinator();
  });

  // -------------------------------------------------------------------------
  // CUJ 1: 이벤트 생성 — 반복 설정 섹션
  // -------------------------------------------------------------------------

  cujGroup('1-1', '반복 설정 ON → 주기·요일·종료 선택', () {
    cujCase(
      'happy: 토글 ON → 매주 패턴 칩 3개 노출',
      app: const Scaffold(
        body: SingleChildScrollView(child: RecurrenceSettingsSection()),
      ),
      body: (t) async {
        // 기본 OFF 상태 확인
        expect(find.text('매주'), findsNothing);

        // 반복 설정 토글 ON
        final toggle = find.byType(Switch);
        await t.tap(toggle);
        await t.pumpAndSettle();

        // 패턴 칩 3개 노출 (매주 / 격주 / 매월)
        expect(find.text('매주'), findsOneWidget);
        expect(find.text('격주'), findsOneWidget);
        expect(find.text('매월'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 매월 선택 → 요일 대신 일 선택 UI 표시',
      app: const Scaffold(
        body: SingleChildScrollView(child: RecurrenceSettingsSection()),
      ),
      body: (t) async {
        // 토글 ON
        await t.tap(find.byType(Switch));
        await t.pumpAndSettle();

        // 매월 패턴 선택
        await t.tap(find.text('매월'));
        await t.pumpAndSettle();

        // 매월: _MonthDayInput 표시 → "매월 반복일" 라벨
        expect(find.text('매월 반복일'), findsOneWidget);
        // 매월: _DayOfWeekChips 숨김 → "요일 선택" 없음
        expect(find.text('요일 선택'), findsNothing);
      },
    );

    cujCase(
      'edge: 격주 선택 → 요일 선택 UI 유지',
      app: const Scaffold(
        body: SingleChildScrollView(child: RecurrenceSettingsSection()),
      ),
      body: (t) async {
        await t.tap(find.byType(Switch));
        await t.pumpAndSettle();

        await t.tap(find.text('격주'));
        await t.pumpAndSettle();

        // 격주 = _DayOfWeekChips 표시 → "요일 선택" 라벨
        expect(find.text('요일 선택'), findsOneWidget);
        // 요일 선택 FilterChip 존재 확인
        expect(find.byType(FilterChip), findsWidgets);
      },
    );
  });

  cujGroup('1-2', '미리보기 — 생성될 날짜 목록 표시', () {
    cujCase(
      'happy: 반복 ON + 매주 월요일 → 미리보기 날짜 노출',
      app: const Scaffold(
        body: SingleChildScrollView(child: RecurrenceSettingsSection()),
      ),
      body: (t) async {
        // 토글 ON (기본값: 매주 월요일 daysOfWeek=[1])
        await t.tap(find.byType(Switch));
        await t.pumpAndSettle();

        // previewDates() 반환 → "예정 일정" 헤더 표시 확인
        expect(find.text('예정 일정'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 반복 OFF → 미리보기 없음',
      app: const Scaffold(
        body: SingleChildScrollView(child: RecurrenceSettingsSection()),
      ),
      body: (t) async {
        // 기본 OFF 상태 — 미리보기 없음
        expect(find.text('총'), findsNothing);
      },
    );
  });

  cujGroup('1-3', '저장 → 즉시 1개월 윈도우 일괄 생성', () {
    cujCase(
      'happy: submit 시 createEvent + recurrenceRule.create 호출',
      app: const Scaffold(body: SizedBox.shrink()),
      overrides: () {
        when(
          () => mockPartyRepo.createEvent(any()),
        ).thenAnswer((invocation) async {
          final event = invocation.positionalArguments.first as Event;
          return event.copyWith(id: 'event-created-1');
        });
        when(
          () => mockRepo.create(
            partyId: any(named: 'partyId'),
            pattern: any(named: 'pattern'),
            daysOfWeek: any(named: 'daysOfWeek'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            monthDay: any(named: 'monthDay'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => _makeRule());

        return [
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          locationRepositoryProvider.overrideWithValue(mockLocationRepo),
          recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
          recurrenceSettingsControllerProvider.overrideWith(
            _EnabledRecurrenceSettingsController.new,
          ),
        ];
      },
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );

        await container
            .read(eventCreateControllerProvider('party-1').notifier)
            .submit();

        verify(() => mockPartyRepo.createEvent(any())).called(1);
        verify(
          () => mockRepo.create(
            partyId: 'party-1',
            pattern: RecurrencePattern.weekly,
            daysOfWeek: [1, 3],
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        ).called(1);
      },
    );
  });

  cujGroup('1-4', '반복 OFF 로 기존 단일 생성 흐름 유지', () {
    cujCase(
      'happy: 기본 상태 — 반복 OFF (Switch off)',
      app: const Scaffold(
        body: SingleChildScrollView(child: RecurrenceSettingsSection()),
      ),
      body: (t) async {
        // 기본값: Switch OFF
        final switchWidget = t.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isFalse);

        // 패턴 칩 비노출
        expect(find.text('매주'), findsNothing);
        expect(find.text('격주'), findsNothing);
        expect(find.text('매월'), findsNothing);
      },
    );
  });

  // -------------------------------------------------------------------------
  // CUJ 2: 개별 회차 관리 + 반복 표시
  // -------------------------------------------------------------------------

  cujGroup('2-1', '자동 생성 회차 개별 수정 → 시리즈 분리', () {
    cujCase(
      'happy: 회차 카드 탭 시 해당 event detail 진입',
      app: PartyEventManagementTab(party: _makeParty()),
      overrides: () => [
        partyEventsProvider('party-1').overrideWith(
          (ref) async => [
            _makeEvent(),
            _makeEvent(id: 'event-2', title: '2회차'),
          ],
        ),
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => null,
        ),
        partyDetailCoordinatorProvider.overrideWith(
          (ref) => mockPartyDetailCoordinator,
        ),
      ],
      body: (t) async {
        await t.tap(find.text('1회차'));
        await t.pumpAndSettle();

        verify(
          () =>
              mockPartyDetailCoordinator.goToEventDetail('party-1', 'event-1'),
        ).called(1);
      },
    );
  });

  cujGroup('2-2', '개별 회차 취소', () {
    cujCase(
      'happy: 취소 회차와 다른 회차가 함께 유지되고 개별 진입 가능',
      app: PartyEventManagementTab(party: _makeParty()),
      overrides: () => [
        partyEventsProvider('party-1').overrideWith(
          (ref) async => [
            _makeEvent(
              id: 'event-cancelled',
              title: '취소된 회차',
              status: 'cancelled',
            ),
            _makeEvent(id: 'event-active', title: '정상 회차'),
          ],
        ),
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => null,
        ),
        partyDetailCoordinatorProvider.overrideWith(
          (ref) => mockPartyDetailCoordinator,
        ),
      ],
      body: (t) async {
        expect(find.text('취소된 회차'), findsOneWidget);
        expect(find.text('정상 회차'), findsOneWidget);

        await t.tap(find.text('정상 회차'));
        await t.pumpAndSettle();

        verify(
          () => mockPartyDetailCoordinator.goToEventDetail(
            'party-1',
            'event-active',
          ),
        ).called(1);
      },
    );
  });

  cujGroup('2-3', '반복 회차 목록에 반복 아이콘 표시', () {
    cujCase(
      'happy: 반복 규칙 요약 카드에 아이콘 + 매주 라벨 노출',
      app: const Scaffold(body: RecurrenceRuleSummaryCard(partyId: 'party-1')),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => _makeRule(daysOfWeek: [1, 3]),
        ),
        partyDetailCoordinatorProvider.overrideWith(
          (ref) => mockPartyDetailCoordinator,
        ),
      ],
      body: (t) async {
        expect(find.byIcon(Icons.event_repeat), findsOneWidget);
        expect(find.textContaining('매주'), findsOneWidget);
      },
    );
  });

  cujGroup('3-1', '일시정지 — 새 생성 중단, 기존 유지', () {
    cujCase(
      'happy: 활성 규칙 → "일시 정지" 버튼 노출 + 탭 가능',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () {
        when(() => mockRepo.pause(any())).thenAnswer((_) async {});
        return [
          partyRecurrenceRuleProvider('party-1').overrideWith(
            (ref) async => _makeRule(),
          ),
          recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
          recurrenceManagementControllerProvider.overrideWith(
            _FakeNoRuleController.new,
          ),
        ];
      },
      body: (t) async {
        expect(find.text('일시 정지'), findsOneWidget);
        expect(find.text('규칙 취소'), findsOneWidget);
        // 상태 칩: '활성'
        expect(find.text('활성'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 활성 규칙 정보 표시 — 패턴 (매주)',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => _makeRule(),
        ),
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        recurrenceManagementControllerProvider.overrideWith(
          _FakeNoRuleController.new,
        ),
      ],
      body: (t) async {
        // 규칙 정보 카드에 패턴 표시
        expect(find.textContaining('매주'), findsWidgets);
      },
    );
  });

  cujGroup('3-2', '일시정지 후 재개 → 부족분 즉시 생성', () {
    cujCase(
      'happy: 일시정지 규칙 → "재개" 버튼 노출',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () {
        when(() => mockRepo.resume(any())).thenAnswer((_) async {});
        return [
          partyRecurrenceRuleProvider('party-1').overrideWith(
            (ref) async => _makeRule(status: RecurrenceStatus.paused),
          ),
          recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
          recurrenceManagementControllerProvider.overrideWith(
            _FakeNoRuleController.new,
          ),
        ];
      },
      body: (t) async {
        expect(find.text('재개'), findsOneWidget);
        expect(find.text('규칙 취소'), findsOneWidget);
        // 상태 칩: '일시 정지'
        expect(find.text('일시 정지'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 일시정지 상태에서 "재개" + "규칙 취소" 2개 버튼만',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => _makeRule(status: RecurrenceStatus.paused),
        ),
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        recurrenceManagementControllerProvider.overrideWith(
          _FakeNoRuleController.new,
        ),
      ],
      body: (t) async {
        // 상태 칩 "일시 정지" 1개만 표시 (액션 버튼 "일시 정지" 없음)
        expect(find.text('일시 정지'), findsOneWidget);
        // 액션 버튼: "재개"(FilledButton) + "규칙 취소"(OutlinedButton) 2개만
        expect(find.text('재개'), findsOneWidget);
        expect(find.text('규칙 취소'), findsOneWidget);
        // OutlinedButton은 "규칙 취소" 하나뿐 — "일시 정지" OutlinedButton 없음
        expect(find.byType(OutlinedButton), findsOneWidget);
      },
    );
  });

  cujGroup('3-3', '규칙 수정 결과가 관리 화면에 반영', () {
    cujCase(
      'happy: 월간 규칙 + 종료일/마지막 생성일 표시',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => _makeRule(
            pattern: RecurrencePattern.monthly,
            endDate: '2026-12-31',
            lastGeneratedDate: '2026-05-20',
          ),
        ),
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        recurrenceManagementControllerProvider.overrideWith(
          _FakeNoRuleController.new,
        ),
      ],
      body: (t) async {
        expect(find.text('매월'), findsOneWidget);
        expect(find.text('2026-12-31'), findsOneWidget);
        expect(find.text('2026-05-20'), findsOneWidget);
      },
    );
  });

  cujGroup('3-4', '반복 해제 — 완전 종료 (불가역)', () {
    cujCase(
      'happy: 활성 규칙 → "규칙 취소" 버튼 탭 → 확인 다이얼로그',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () {
        when(() => mockRepo.cancel(any())).thenAnswer((_) async {});
        return [
          partyRecurrenceRuleProvider('party-1').overrideWith(
            (ref) async => _makeRule(),
          ),
          recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
          recurrenceManagementControllerProvider.overrideWith(
            _FakeNoRuleController.new,
          ),
        ];
      },
      body: (t) async {
        // "규칙 취소" 버튼 탭
        await t.tap(find.text('규칙 취소'));
        await t.pumpAndSettle();

        // 확인 다이얼로그 노출 (불가역 안내)
        expect(find.text('취소하기'), findsOneWidget);
      },
    );

    cujCase(
      'edge: 이미 취소된 규칙 → 재활성화 불가 메시지 + 액션 버튼 없음',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => _makeRule(status: RecurrenceStatus.cancelled),
        ),
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        recurrenceManagementControllerProvider.overrideWith(
          _FakeNoRuleController.new,
        ),
      ],
      body: (t) async {
        expect(
          find.textContaining('취소된 규칙은 재활성화할 수 없습니다'),
          findsOneWidget,
        );
        expect(find.text('일시 정지'), findsNothing);
        expect(find.text('재개'), findsNothing);
      },
    );

    cujCase(
      'edge: 반복 규칙 없음 → 빈 상태 메시지',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => null,
        ),
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        recurrenceManagementControllerProvider.overrideWith(
          _FakeNoRuleController.new,
        ),
      ],
      body: (t) async {
        expect(find.textContaining('설정된 반복 규칙이 없습니다'), findsOneWidget);
      },
    );
  });

  cujGroup('4-1', '매일 새벽 크론으로 1개월 윈도우 유지', () {
    cujCase(
      'happy: 관리 화면에서 마지막 생성일/패턴 정보 확인 가능',
      app: const RecurrenceManagementScreen(partyId: 'party-1'),
      overrides: () => [
        partyRecurrenceRuleProvider('party-1').overrideWith(
          (ref) async => _makeRule(lastGeneratedDate: '2026-05-28'),
        ),
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        recurrenceManagementControllerProvider.overrideWith(
          _FakeNoRuleController.new,
        ),
      ],
      body: (t) async {
        expect(find.text('반복 패턴'), findsOneWidget);
        expect(find.text('마지막 생성일'), findsOneWidget);
        expect(find.text('2026-05-28'), findsOneWidget);
      },
    );
  });

  cujGroup('4-2', '크론 실패 시 재시도 + 운영팀 알림', () {
    cujCase(
      'edge: resume 실패 후 같은 액션을 재시도할 수 있음',
      app: const Scaffold(body: SizedBox.shrink()),
      overrides: () {
        var attempt = 0;
        when(() => mockRepo.resume('rule-1')).thenAnswer((_) async {
          attempt++;
          if (attempt == 1) {
            throw Exception('cron failed once');
          }
        });
        return [
          recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
        ];
      },
      body: (t) async {
        final container = ProviderScope.containerOf(
          t.element(find.byType(Scaffold)),
        );
        final controller = container.read(
          recurrenceManagementControllerProvider.notifier,
        );

        await controller.resume('rule-1');
        expect(
          container.read(recurrenceManagementControllerProvider).hasError,
          isTrue,
        );

        await controller.resume('rule-1');
        expect(
          container.read(recurrenceManagementControllerProvider).hasError,
          isFalse,
        );

        verify(() => mockRepo.resume('rule-1')).called(2);
      },
    );
  });
}
