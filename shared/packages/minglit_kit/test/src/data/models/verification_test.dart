import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/models/verification_submission.dart';

/// Deep-encodes a map through JSON codec to convert nested Freezed objects
/// back to raw `Map<String, dynamic>`.
Map<String, dynamic> _deepEncode(Map<String, dynamic> map) {
  return jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
}

void main() {
  final now = DateTime(2026, 1, 15, 12);

  group('VerificationFormField', () {
    test('creates from JSON', () {
      final field = VerificationFormField.fromJson({
        'key': 'company_name',
        'type': 'text',
        'label': '회사명',
        'required': true,
        'placeholder': '회사명을 입력하세요',
        'options': ['Option A', 'Option B'],
      });

      expect(field.key, 'company_name');
      expect(field.type, 'text');
      expect(field.label, '회사명');
      expect(field.required, isTrue);
      expect(field.placeholder, '회사명을 입력하세요');
      expect(field.options, ['Option A', 'Option B']);
    });

    test('creates with defaults', () {
      final field = VerificationFormField.fromJson({
        'key': 'doc',
        'type': 'file',
        'label': '서류',
      });

      expect(field.required, isTrue);
      expect(field.placeholder, isNull);
      expect(field.options, isNull);
    });

    test('serializes to JSON and back', () {
      final original = VerificationFormField.fromJson({
        'key': 'company_name',
        'type': 'text',
        'label': '회사명',
        'required': false,
        'placeholder': 'Enter',
      });
      final json = original.toJson();
      final restored = VerificationFormField.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('Verification', () {
    Map<String, dynamic> verificationJson() => {
          'id': 'verif_1',
          'category': 'career',
          'internal_name': 'global_career',
          'display_name': '직장 인증',
          'partner_id': 'partner_1',
          'description': 'Career verification',
          'icon_key': 'briefcase',
          'form_schema': [
            {'key': 'company', 'type': 'text', 'label': '회사명'},
          ],
          'is_active': true,
          'created_at': now.toIso8601String(),
        };

    test('creates from JSON with all fields', () {
      final v = Verification.fromJson(verificationJson());

      expect(v.id, 'verif_1');
      expect(v.category, VerificationCategory.career);
      expect(v.internalName, 'global_career');
      expect(v.displayName, '직장 인증');
      expect(v.partnerId, 'partner_1');
      expect(v.description, 'Career verification');
      expect(v.iconKey, 'briefcase');
      expect(v.formSchema, hasLength(1));
      expect(v.formSchema.first.key, 'company');
      expect(v.isActive, isTrue);
    });

    test('creates with minimal fields and defaults', () {
      final v = Verification.fromJson({
        'id': 'v1',
        'category': 'asset',
        'internal_name': 'test',
        'display_name': 'Test',
      });

      expect(v.category, VerificationCategory.asset);
      expect(v.partnerId, isNull);
      expect(v.description, isNull);
      expect(v.iconKey, isNull);
      expect(v.formSchema, isEmpty);
      expect(v.isActive, isTrue);
    });

    test('serializes to JSON and back', () {
      final original = Verification.fromJson(verificationJson());
      // toJson produces nested Freezed objects; re-encode through JSON codec
      final json = _deepEncode(original.toJson());
      final restored = Verification.fromJson(json);

      expect(restored, equals(original));
    });

    test('toDbJson removes id and created_at', () {
      final v = Verification.fromJson(verificationJson());
      final dbJson = v.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('internal_name'), isTrue);
    });

    test('all verification categories parse', () {
      for (final cat in [
        'career',
        'asset',
        'marriage',
        'academic',
        'vehicle',
        'etc',
      ]) {
        final v = Verification.fromJson({
          'id': 'v1',
          'category': cat,
          'internal_name': 'test',
          'display_name': 'Test',
        });
        expect(v.category, isNotNull);
      }
    });

    test('handles nullable description and iconKey fields (Fix #42)', () {
      // Test that null values in DB fields don't cause parse errors
      final v = Verification.fromJson({
        'id': 'v1',
        'category': 'career',
        'internal_name': 'test',
        'display_name': 'Test',
        'description': null,
        'icon_key': null,
      });

      expect(v.description, isNull);
      expect(v.iconKey, isNull);
      expect(v.id, 'v1');
    });

    test('handles mixed null and non-null nullable fields', () {
      final v = Verification.fromJson({
        'id': 'v2',
        'category': 'asset',
        'internal_name': 'asset_test',
        'display_name': 'Asset Test',
        'description': 'Asset verification',
        'icon_key': null,
      });

      expect(v.description, 'Asset verification');
      expect(v.iconKey, isNull);
    });
  });

  group('VerificationRequirementStatus', () {
    Verification baseMaster() => Verification.fromJson({
          'id': 'v1',
          'category': 'career',
          'internal_name': 'test',
          'display_name': 'Test',
        });

    test('creates with master only', () {
      final status = VerificationRequirementStatus(master: baseMaster());

      expect(status.isApproved, isFalse);
      expect(status.hasActiveRequest, isFalse);
      expect(status.status, isNull);
    });

    test('isApproved when verifiedResult exists', () {
      final status = VerificationRequirementStatus(
        master: baseMaster(),
        verifiedResult: {'company': 'Minglit'},
      );

      expect(status.isApproved, isTrue);
    });

    test('hasActiveRequest when submission exists', () {
      final submission = VerificationSubmission.fromJson({
        'id': 'sub_1',
        'partner_id': 'p1',
        'user_id': 'u1',
        'verification_id': 'v1',
        'status': 'pending',
        'snapshot_data': {'company': 'Test'},
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      final status = VerificationRequirementStatus(
        master: baseMaster(),
        activeSubmission: submission,
      );

      expect(status.hasActiveRequest, isTrue);
      expect(status.status, VerificationStatus.pending);
    });

    test('serializes to JSON and back', () {
      final original = VerificationRequirementStatus(
        master: baseMaster(),
        verifiedResult: {'key': 'value'},
      );
      // toJson produces nested Freezed objects; re-encode through JSON codec
      final json = _deepEncode(original.toJson());
      final restored = VerificationRequirementStatus.fromJson(json);

      expect(restored.master.id, original.master.id);
      expect(restored.verifiedResult, original.verifiedResult);
    });
  });
}
