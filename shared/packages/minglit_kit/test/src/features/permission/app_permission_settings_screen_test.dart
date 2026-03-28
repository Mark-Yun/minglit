import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:minglit_kit/src/features/permission/app_permission_settings_screen.dart';
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

    when(
      () => mockGeolocator.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockGeolocator.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
  });

  Widget buildSubject() {
    return const MaterialApp(
      home: AppPermissionSettingsScreen(),
    );
  }

  group('AppPermissionSettingsScreen', () {
    testWidgets(
      'shows 권한 설정 app bar title',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('권한 설정'), findsOneWidget);
      },
    );

    testWidgets(
      'shows location permission with granted status',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('위치'), findsOneWidget);
        expect(find.text('허용됨'), findsOneWidget);
      },
    );

    testWidgets(
      'shows location as denied when permission denied',
      (tester) async {
        when(
          () => mockGeolocator.checkPermission(),
        ).thenAnswer(
          (_) async => LocationPermission.denied,
        );

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('위치'), findsOneWidget);
        // Location + notification both show 거부됨 in test
        expect(find.text('거부됨'), findsAtLeast(1));
      },
    );

    testWidgets(
      'shows location as disabled when service off',
      (tester) async {
        when(
          () => mockGeolocator.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.text('위치'), findsOneWidget);
        expect(find.text('비활성'), findsOneWidget);
      },
    );

    testWidgets(
      'shows system settings button',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(
          find.text('시스템 설정 열기'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping system settings button calls openAppSettings',
      (tester) async {
        when(
          () => mockGeolocator.openAppSettings(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await tester.tap(find.text('시스템 설정 열기'));
        await tester.pumpAndSettle();

        verify(() => mockGeolocator.openAppSettings()).called(1);
      },
    );
  });
}
