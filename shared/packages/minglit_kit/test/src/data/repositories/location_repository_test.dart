import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/location_repository.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late LocationRepository repository;

  final now = DateTime.now();
  final locationJson = {
    'id': 'loc_1',
    'partner_id': 'partner_1',
    'name': '강남 밍글릿 라운지',
    'address': '서울시 강남구 테헤란로 123',
    'address_detail': '2층',
    'region_1': '서울',
    'region_2': '강남구',
    'region_3': '역삼동',
    'directions_guide': '2번 출구에서 도보 3분',
    'postal_code': '06134',
    'lat': 37.5012,
    'lng': 127.0396,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  };

  setUp(() {
    mockClient = createMockSupabase();
    repository = LocationRepository(supabase: mockClient);
  });

  group('LocationRepository', () {
    group('getLocationById', () {
      test('returns location when found', () async {
        mockTable(
          mockClient,
          'locations_view',
          maybeSingleData: locationJson,
        );

        final result = await repository.getLocationById('loc_1');

        expect(result, isNotNull);
        expect(result!.id, 'loc_1');
        expect(result.name, '강남 밍글릿 라운지');
        expect(result.latitude, 37.5012);
        expect(result.longitude, 127.0396);
      });

      test('returns null when not found', () async {
        mockTable(
          mockClient,
          'locations_view',
          maybeSingleData: null,
        );

        final result = await repository.getLocationById('loc_unknown');
        expect(result, isNull);
      });
    });

    group('getLocations', () {
      test('returns locations for partner', () async {
        mockTable(
          mockClient,
          'locations_view',
          selectData: [locationJson],
        );

        final result = await repository.getLocations('partner_1');

        expect(result, hasLength(1));
        expect(result.first.name, '강남 밍글릿 라운지');
        expect(result.first.partnerId, 'partner_1');
      });

      test('returns empty list when no locations', () async {
        mockTable(mockClient, 'locations_view', selectData: []);

        final result = await repository.getLocations('partner_none');
        expect(result, isEmpty);
      });
    });

    group('createLocation', () {
      test('creates and returns new location', () async {
        final createdJson = {
          'id': 'loc_new',
          'partner_id': 'partner_1',
          'name': '새 장소',
          'address': '서울시 마포구',
          'address_detail': null,
          'region_1': '서울',
          'region_2': '마포구',
          'region_3': null,
          'directions_guide': null,
          'postal_code': '04100',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        mockTable(
          mockClient,
          'locations',
          insertReturnData: createdJson,
        );

        final location = (await (() async {
          // Create a Location from the test JSON
          // (uses locations_view for reads, locations for writes)
          return locationJson;
        })());

        // Parse it manually since Location.fromJson expects locations_view format
        mockTable(
          mockClient,
          'locations',
          insertReturnData: {
            ...createdJson,
            'lat': 37.5555,
            'lng': 126.9220,
          },
        );

        // We test that createLocation does not throw
        final newLoc = await repository.createLocation(
          (await (() async {
            mockTable(
              mockClient,
              'locations_view',
              maybeSingleData: locationJson,
            );
            return (await repository.getLocationById('loc_1'))!;
          })()),
        );

        expect(newLoc.id, isNotEmpty);
      });
    });

    group('updateLocationDetails', () {
      test('completes without error', () async {
        mockTable(mockClient, 'locations');

        await expectLater(
          repository.updateLocationDetails(
            locationId: 'loc_1',
            addressDetail: '3층으로 변경',
            directionsGuide: '3번 출구에서 도보 5분',
          ),
          completes,
        );
      });
    });
  });
}
