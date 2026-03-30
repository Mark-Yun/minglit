import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:minglit_kit/src/services/location_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

void main() {
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
  });

  group('LocationService', () {
    test(
      'returns LocationResult when permission granted and service enabled',
      () async {
        when(
          () => mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          () => mockGeolocator.getLastKnownPosition(),
        ).thenAnswer((_) async => null);
        when(
          () => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        ).thenAnswer(
          (_) async => Position(
            latitude: 37.4979,
            longitude: 127.0276,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );

        final service = LocationService();
        final result = await service.getCurrentPosition();

        expect(result, isNotNull);
        expect(result!.latitude, 37.4979);
        expect(result.longitude, 127.0276);
      },
    );

    test('returns null when location service disabled', () async {
      when(
        () => mockGeolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);

      final service = LocationService();
      final result = await service.getCurrentPosition();

      expect(result, isNull);
    });

    test('returns null when permission denied', () async {
      when(
        () => mockGeolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => mockGeolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      final service = LocationService();
      final result = await service.getCurrentPosition();

      expect(result, isNull);
    });

    test('returns null when permission denied forever', () async {
      when(
        () => mockGeolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      final service = LocationService();
      final result = await service.getCurrentPosition();

      expect(result, isNull);
    });

    test('requests permission when initially denied then granted', () async {
      when(
        () => mockGeolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        () => mockGeolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        () => mockGeolocator.getLastKnownPosition(),
      ).thenAnswer((_) async => null);
      when(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenAnswer(
        (_) async => Position(
          latitude: 37.5665,
          longitude: 126.9780,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      final service = LocationService();
      final result = await service.getCurrentPosition();

      expect(result, isNotNull);
      expect(result!.latitude, 37.5665);
      verify(() => mockGeolocator.requestPermission()).called(1);
    });

    // Fix #419: Test getLastKnownPosition fast path
    test(
      'returns last known position without calling getCurrentPosition',
      () async {
        when(
          () => mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          () => mockGeolocator.getLastKnownPosition(),
        ).thenAnswer(
          (_) async => Position(
            latitude: 37.4979,
            longitude: 127.0276,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );

        final service = LocationService();
        final result = await service.getCurrentPosition();

        expect(result, isNotNull);
        expect(result!.latitude, 37.4979);
        expect(result.longitude, 127.0276);
        verifyNever(
          () => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        );
      },
    );

    // Fix #419: Test fallback to getCurrentPosition when no last known
    test(
      'falls back to getCurrentPosition when no last known position',
      () async {
        when(
          () => mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => mockGeolocator.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          () => mockGeolocator.getLastKnownPosition(),
        ).thenAnswer((_) async => null);
        when(
          () => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        ).thenAnswer(
          (_) async => Position(
            latitude: 37.5665,
            longitude: 126.9780,
            timestamp: DateTime.now(),
            accuracy: 10,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ),
        );

        final service = LocationService();
        final result = await service.getCurrentPosition();

        expect(result, isNotNull);
        expect(result!.latitude, 37.5665);
        verify(
          () => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          ),
        ).called(1);
      },
    );
  });

  group('LocationService.hasPermission', () {
    test('returns true when permission is whileInUse', () async {
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);

      final service = LocationService();
      expect(await service.hasPermission(), isTrue);
    });

    test('returns true when permission is always', () async {
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.always);

      final service = LocationService();
      expect(await service.hasPermission(), isTrue);
    });

    test('returns false when permission is denied', () async {
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      final service = LocationService();
      expect(await service.hasPermission(), isFalse);
    });

    test('returns false when permission is deniedForever', () async {
      when(
        () => mockGeolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      final service = LocationService();
      expect(await service.hasPermission(), isFalse);
    });
  });
}
