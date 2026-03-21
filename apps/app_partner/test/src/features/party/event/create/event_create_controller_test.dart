import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

Party _makeParty({
  String id = 'party-1',
  String? locationId,
  List<EntryGroupTemplate>? entryGroups,
}) {
  final now = DateTime.now();
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: now,
    updatedAt: now,
    locationId: locationId,
    maxParticipants: 30,
    contactOptions: {'phone': '010-1234-5678'},
    entryGroups: entryGroups,
  );
}

Location _makeLocation({String id = 'loc-1'}) {
  final now = DateTime.now();
  return Location(
    id: id,
    partnerId: 'partner-1',
    name: 'Test Venue',
    address: '서울시 강남구',
    addressDetail: '3층',
    directionsGuide: '엘리베이터 이용',
    createdAt: now,
    updatedAt: now,
  );
}

TicketTemplate _makeTemplate({String id = 'tmpl-1'}) {
  final now = DateTime.now();
  return TicketTemplate(
    id: id,
    partyId: 'party-1',
    name: 'General Ticket',
    price: 15000,
    quantity: 50,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockLocationRepository mockLocationRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockLocationRepo = MockLocationRepository();
    registerFallbackValue(Event(
      id: '',
      partyId: '',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    registerFallbackValue(Location(
      id: '',
      partnerId: '',
      name: '',
      address: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  group('EventCreateController', () {
    group('build', () {
      test('initializes with default state', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.partyId, 'party-1');
        expect(state.maxParticipants, 20);
        expect(state.title, '');
        expect(state.description, isEmpty);
        expect(state.tickets, isEmpty);
        expect(state.entryGroups, isEmpty);
        expect(state.endTime.isAfter(state.startTime), isTrue);
      });
    });

    group('initWithParty', () {
      test('populates state from party template', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        final party = _makeParty(locationId: 'loc-1');
        final templates = [_makeTemplate()];
        final location = _makeLocation();

        notifier.initWithParty(
          party: party,
          templates: templates,
          location: location,
        );

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.title, 'Test Party');
        expect(state.maxParticipants, 30);
        expect(state.contactOptions, {'phone': '010-1234-5678'});
        expect(state.tickets, hasLength(1));
        expect(state.tickets.first.name, 'General Ticket');
        expect(state.locationId, 'loc-1');
        expect(state.selectedLocation, location);
        expect(state.addressDetail, '3층');
        expect(state.directionsGuide, '엘리베이터 이용');
      });

      test('handles party without location', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        notifier.initWithParty(
          party: _makeParty(),
          templates: [],
          location: null,
        );

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.locationId, isNull);
        expect(state.selectedLocation, isNull);
        expect(state.tickets, isEmpty);
      });

      test('maps entry group templates to instances', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        final entryGroupTemplates = [
          EntryGroupTemplate(
            id: 'eg-1',
            partyId: 'party-1',
            label: 'Male',
            gender: 'male',
          ),
        ];

        notifier.initWithParty(
          party: _makeParty(entryGroups: entryGroupTemplates),
          templates: [],
          location: null,
        );

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.entryGroups, hasLength(1));
        expect(state.entryGroups.first.label, 'Male');
        expect(state.entryGroups.first.gender, 'male');
      });
    });

    group('update methods', () {
      test('updateStartTime updates start and adjusts end if needed', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        final originalState = container.read(
          eventCreateControllerProvider('party-1'),
        );

        // Set start time far in the future (past the current end time)
        final farFuture = originalState.endTime.add(const Duration(days: 1));
        notifier.updateStartTime(farFuture);

        final updated = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(updated.startTime, farFuture);
        expect(updated.endTime.isAfter(farFuture), isTrue);
      });

      test('updateStartTime does not change end if end is after new start',
          () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        final originalState = container.read(
          eventCreateControllerProvider('party-1'),
        );
        final originalEnd = originalState.endTime;

        // Set start time before end time
        final newStart = originalEnd.subtract(const Duration(hours: 5));
        notifier.updateStartTime(newStart);

        final updated = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(updated.startTime, newStart);
        expect(updated.endTime, originalEnd);
      });

      test('updateEndTime updates end time', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        final newEnd = DateTime(2030, 1, 1, 23, 0);
        notifier.updateEndTime(newEnd);

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.endTime, newEnd);
      });

      test('updateMaxParticipants sets count', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateMaxParticipants(100);

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.maxParticipants, 100);
      });

      test('updateTitle sets title', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateTitle('New Title');

        expect(
          container.read(eventCreateControllerProvider('party-1')).title,
          'New Title',
        );
      });

      test('updateTitle with null sets empty string', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateTitle(null);

        expect(
          container.read(eventCreateControllerProvider('party-1')).title,
          '',
        );
      });

      test('updateDescription sets description', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateDescription({'ops': []});

        expect(
          container
              .read(eventCreateControllerProvider('party-1'))
              .description,
          {'ops': []},
        );
      });

      test('updateImageUrl sets imageUrl', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateImageUrl('https://example.com/img.jpg');

        expect(
          container
              .read(eventCreateControllerProvider('party-1'))
              .imageUrl,
          'https://example.com/img.jpg',
        );
      });

      test('updateContactOptions sets options', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateContactOptions({'kakao': 'open-chat-link'});

        expect(
          container
              .read(eventCreateControllerProvider('party-1'))
              .contactOptions,
          {'kakao': 'open-chat-link'},
        );
      });

      test('updateLocation sets location and locationId', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        final location = _makeLocation();
        notifier.updateLocation(location);

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.selectedLocation, location);
        expect(state.locationId, 'loc-1');
      });

      test('updateLocation with null clears location', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateLocation(null);

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.selectedLocation, isNull);
        expect(state.locationId, isNull);
      });

      test('updateAddressDetail and updateDirections', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.updateAddressDetail('5층 501호');
        notifier.updateDirections('정문 좌측');

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.addressDetail, '5층 501호');
        expect(state.directionsGuide, '정문 좌측');
      });

      test('setVisibility updates visibility', () {
        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );
        notifier.setVisibility('private');

        expect(
          container
              .read(eventCreateControllerProvider('party-1'))
              .visibility,
          'private',
        );
      });
    });

    group('submit', () {
      test('creates event without new location when locationId exists',
          () async {
        final party = _makeParty(locationId: 'loc-1');

        when(() => mockPartyRepo.createEvent(any()))
            .thenAnswer((_) async => Event(
                  id: 'new-event',
                  partyId: 'party-1',
                  startTime: DateTime.now(),
                  endTime: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            partyDetailProvider('party-1').overrideWith(
              (ref) async => party,
            ),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        // Set locationId (simulating initWithParty)
        notifier.updateLocation(_makeLocation());
        notifier.updateTitle('Event Title');

        await notifier.submit();

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.status, isA<AsyncData<void>>());
        verify(() => mockPartyRepo.createEvent(any())).called(1);
        verifyNever(() => mockLocationRepo.createLocation(any()));
      });

      test('creates location first when selectedLocation has no id',
          () async {
        final party = _makeParty();
        final newLocation = _makeLocation(id: 'new-loc');

        when(() => mockLocationRepo.createLocation(any()))
            .thenAnswer((_) async => newLocation);
        when(() => mockPartyRepo.createEvent(any()))
            .thenAnswer((_) async => Event(
                  id: 'new-event',
                  partyId: 'party-1',
                  startTime: DateTime.now(),
                  endTime: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            partyDetailProvider('party-1').overrideWith(
              (ref) async => party,
            ),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        // Set selectedLocation but without locationId
        final locationWithoutId = Location(
          id: '',
          partnerId: '',
          name: 'New Place',
          address: '서울시 마포구',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        notifier.updateLocation(locationWithoutId);
        // Clear locationId to simulate a new location
        notifier.updateLocation(locationWithoutId.copyWith(id: ''));

        await notifier.submit();

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.status, isA<AsyncData<void>>());
        verify(() => mockLocationRepo.createLocation(any())).called(1);
        verify(() => mockPartyRepo.createEvent(any())).called(1);
      });

      test('sets error status on repository failure', () async {
        when(() => mockPartyRepo.createEvent(any()))
            .thenThrow(Exception('Create failed'));

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-1').notifier,
        );

        await notifier.submit();

        final state = container.read(
          eventCreateControllerProvider('party-1'),
        );

        expect(state.status, isA<AsyncError<void>>());
      });
    });
  });
}
