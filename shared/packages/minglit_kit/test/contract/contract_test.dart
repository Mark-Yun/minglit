/// Contract tests: verify that Flutter Freezed models can parse the shared
/// JSON samples used by Edge Function contract tests.
///
/// If an Edge Function changes a field name, the shared sample is updated,
/// and this test fails — catching the mismatch before runtime.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event_application.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';

/// Resolve the shared schemas directory relative to the package root.
String _samplesDir() {
  // test is run from shared/packages/minglit_kit/
  final packageRoot = Directory.current.path;
  return '$packageRoot/../../../shared/schemas/samples';
}

Map<String, dynamic> _loadSample(String name) {
  final file = File('${_samplesDir()}/$name.json');
  if (!file.existsSync()) {
    fail('Sample file not found: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('Contract: EventApplication model ↔ shared sample', () {
    test('parses event_application sample without error', () {
      final json = _loadSample('event_application');
      final model = EventApplication.fromJson(json);

      expect(model.id, 'app-001');
      expect(model.eventId, 'evt-001');
      expect(model.ticketId, 'tkt-001');
      expect(model.userId, 'user-001');
      expect(model.status, 'approved');
      expect(model.paymentId, 'imp_123456789');
      expect(model.paymentAmount, 15000);
      expect(model.refundStatus, 'none');
      expect(model.paidAt, isNotNull);
    });

    test('round-trips through toJson → fromJson', () {
      final json = _loadSample('event_application');
      final model = EventApplication.fromJson(json);
      final roundTripped = EventApplication.fromJson(model.toJson());

      expect(roundTripped.id, model.id);
      expect(roundTripped.eventId, model.eventId);
      expect(roundTripped.paymentId, model.paymentId);
      expect(roundTripped.paymentAmount, model.paymentAmount);
      expect(roundTripped.refundStatus, model.refundStatus);
    });
  });

  group('Contract: UserProfile model ↔ shared sample', () {
    test('parses user_profile sample without error', () {
      final json = _loadSample('user_profile');
      final model = UserProfile.fromJson(json);

      expect(model.id, 'user-001');
      expect(model.name, 'Test User');
      expect(model.username, 'testuser');
      expect(model.phoneNumber, '01012341234');
      expect(model.gender, 'female');
      expect(model.isVerified, true);
      expect(model.birthDate, isNotNull);
    });

    test('round-trips through toJson → fromJson', () {
      final json = _loadSample('user_profile');
      final model = UserProfile.fromJson(json);
      final roundTripped = UserProfile.fromJson(model.toJson());

      expect(roundTripped.id, model.id);
      expect(roundTripped.name, model.name);
      expect(roundTripped.phoneNumber, model.phoneNumber);
      expect(roundTripped.gender, model.gender);
      expect(roundTripped.isVerified, model.isVerified);
    });
  });

  group('Contract: Edge Function response shapes', () {
    test('payment-verify success has expected fields', () {
      final json = _loadSample('payment_verify_success');
      expect(json['success'], true);
      expect(json['imp_uid'], isA<String>());
      expect((json['imp_uid'] as String).isNotEmpty, true);
    });

    test('payment-cancel success has expected fields', () {
      final json = _loadSample('payment_cancel_success');
      expect(json['success'], true);
      expect(json['data'], isA<Map>());
    });

    test('settlement-query settlements has expected fields', () {
      final json = _loadSample('settlement_query_settlements');
      expect(json['success'], true);
      expect(json['settlements'], isA<List>());
      final first = (json['settlements'] as List).first as Map;
      expect(first['id'], isA<String>());
      expect(first['partnerId'], isA<String>());
      expect(first['amount'], isA<num>());
      expect(first['currency'], isA<String>());
    });

    test('settlement-query payouts has expected fields', () {
      final json = _loadSample('settlement_query_payouts');
      expect(json['success'], true);
      expect(json['payouts'], isA<List>());
      final first = (json['payouts'] as List).first as Map;
      expect(first['id'], isA<String>());
      expect(first['partnerId'], isA<String>());
      expect(first['amount'], isA<num>());
    });

    test('identity-verify success has expected fields', () {
      final json = _loadSample('identity_verify_success');
      expect(json['success'], true);
      expect(json['user'], isA<String>());
    });

    test('profile-update success has expected fields', () {
      final json = _loadSample('profile_update_success');
      expect(json['success'], true);
      expect(json['processed'], isA<Map>());
      final processed = json['processed'] as Map;
      expect(processed['user_id'], isA<String>());
      expect(processed['action_type'], isA<String>());
      expect(processed['weight'], isA<num>());
    });
  });
}
