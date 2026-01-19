import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_identification/minglit_identification.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';

class MockBuildContext extends Mock implements BuildContext {}

class MockIdentificationProvider extends Mock implements IdentificationProvider {}

void main() {
  group('IdentificationProvider Interface Tests', () {
    test('Should be able to use MockIdentificationProvider', () async {
      final mockProvider = MockIdentificationProvider();
      final context = MockBuildContext();

      when(() => mockProvider.verify(
            context: context,
            merchantUid: 'TEST_UID',
          )).thenAnswer((_) async => 'mock_verification_id');

      final result = await mockProvider.verify(
        context: context,
        merchantUid: 'TEST_UID',
      );

      expect(result, 'mock_verification_id');
    });

    test('IdentificationProviderImpl should exist on all platforms via stub/impl', () {
      // This test ensures that the conditional import logic is valid
      // and doesn't break compilation on Dart VM.
      final provider = IdentificationProviderImpl();
      expect(provider, isNotNull);
      expect(provider, isA<IdentificationProvider>());
    });
  });
}
