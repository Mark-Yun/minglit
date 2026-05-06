import 'package:app_partner/src/features/party/event/edit/event_edit_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_data.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../utils/mocks.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockEventRepository mockRepo;

  final now = DateTime(2026, 5, 6, 19);

  Event makeEvent({int currentParticipants = 0, String title = '테스트 이벤트'}) {
    return Event(
      id: 'event_1',
      partyId: 'party_1',
      title: title,
      startTime: now,
      endTime: now.add(const Duration(hours: 2)),
      createdAt: now,
      updatedAt: now,
      maxParticipants: 20,
      currentParticipants: currentParticipants,
    );
  }

  setUp(() {
    mockRepo = MockEventRepository();
  });

  ProviderContainer makeContainer({SupabaseClient? supabaseClient}) {
    final container = ProviderContainer(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockRepo),
        if (supabaseClient != null)
          supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('EventEditController', () {
    group('build', () {
      test('confirmedCount comes from event.currentParticipants', () async {
        final event = makeEvent(currentParticipants: 3);
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        final state = await container.read(
          eventEditControllerProvider('event_1').future,
        );

        expect(state.confirmedCount, 3);
        expect(state.title, '테스트 이벤트');
        expect(state.isDirty, isFalse);
      });
    });

    group('updateTitle', () {
      test('marks isDirty when title changes', () async {
        final event = makeEvent(title: '원래 제목');
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        await container.read(eventEditControllerProvider('event_1').future);

        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateTitle('새 제목');

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.title, '새 제목');
        expect(state.isDirty, isTrue);
      });

      test('stays clean when title unchanged', () async {
        final event = makeEvent(title: '원래 제목');
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        await container.read(eventEditControllerProvider('event_1').future);

        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateTitle('원래 제목');

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.isDirty, isFalse);
      });
    });

    group('updateMaxParticipants', () {
      test(
        'enforces minimum = confirmedCount when confirmedCount >= 1',
        () async {
          final event = makeEvent(currentParticipants: 5);
          when(
            () => mockRepo.getEventById('event_1'),
          ).thenAnswer((_) async => event);

          final container = makeContainer();
          await container.read(eventEditControllerProvider('event_1').future);

          container
              .read(eventEditControllerProvider('event_1').notifier)
              .updateMaxParticipants(3);

          final state = container
              .read(eventEditControllerProvider('event_1'))
              .value!;
          expect(state.maxParticipants, 5);
        },
      );

      test('enforces minimum = 1 when no confirmed participants', () async {
        final event = makeEvent(currentParticipants: 0);
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        await container.read(eventEditControllerProvider('event_1').future);

        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateMaxParticipants(0);

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.maxParticipants, 1);
      });

      test('accepts valid value above minimum', () async {
        final event = makeEvent(currentParticipants: 3);
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        await container.read(eventEditControllerProvider('event_1').future);

        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateMaxParticipants(30);

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.maxParticipants, 30);
        expect(state.isDirty, isTrue);
      });
    });

    group('updateSchedule', () {
      test('marks isDirty when schedule changes', () async {
        final event = makeEvent();
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        await container.read(eventEditControllerProvider('event_1').future);

        final newStart = now.add(const Duration(hours: 1));
        final newEnd = now.add(const Duration(hours: 3));
        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateSchedule(
              startTime: newStart,
              endTime: newEnd,
              location: null,
            );

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.startTime, newStart);
        expect(state.endTime, newEnd);
        expect(state.isDirty, isTrue);
      });

      test('normalizes endTime when before startTime', () async {
        final event = makeEvent();
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final container = makeContainer();
        await container.read(eventEditControllerProvider('event_1').future);

        final newStart = now.add(const Duration(hours: 2));
        final badEnd = now.add(const Duration(hours: 1));
        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateSchedule(
              startTime: newStart,
              endTime: badEnd,
              location: null,
            );

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.endTime, newStart);
      });
    });

    group('submit — failure recovery', () {
      test('restores isLoading=false on EF error', () async {
        final event = makeEvent(title: '원래 제목');
        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);

        final mockClient = _MockSupabaseClient();
        final mockFunctions = _MockFunctionsClient();
        when(() => mockClient.functions).thenReturn(mockFunctions);
        when(
          () => mockFunctions.invoke(
            any(),
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network error'));

        final container = makeContainer(supabaseClient: mockClient);
        await container.read(eventEditControllerProvider('event_1').future);

        container
            .read(eventEditControllerProvider('event_1').notifier)
            .updateTitle('새 제목');

        await expectLater(
          container
              .read(eventEditControllerProvider('event_1').notifier)
              .submit(),
          throwsA(isA<Exception>()),
        );

        final state = container
            .read(eventEditControllerProvider('event_1'))
            .value!;
        expect(state.isLoading, isFalse);
      });
    });
  });
}
