import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/iamport/data/model/iamport_result_model.dart';

void main() {
  group('IamportResultModel', () {
    group('fromJson', () {
      test('parses successful certification result', () {
        final json = <String, dynamic>{
          'imp_uid': 'imp_123456789',
          'merchant_uid': 'mid_001',
          'success': true,
          'error_msg': null,
          'pg_provider': 'danal',
          'pg_type': 'certification',
        };

        final model = IamportResultModel.fromJson(json);

        expect(model.impUid, 'imp_123456789');
        expect(model.merchantUid, 'mid_001');
        expect(model.success, isTrue);
        expect(model.errorMsg, isNull);
        expect(model.pgProvider, 'danal');
        expect(model.pgType, 'certification');
      });

      test('parses failed certification result', () {
        final json = <String, dynamic>{
          'imp_uid': null,
          'merchant_uid': 'mid_002',
          'success': false,
          'error_msg': 'User cancelled',
          'pg_provider': null,
          'pg_type': null,
        };

        final model = IamportResultModel.fromJson(json);

        expect(model.impUid, isNull);
        expect(model.success, isFalse);
        expect(model.errorMsg, 'User cancelled');
      });

      test('defaults success to false when missing', () {
        final json = <String, dynamic>{
          'imp_uid': 'imp_999',
          'merchant_uid': 'mid_003',
        };

        final model = IamportResultModel.fromJson(json);

        expect(model.success, isFalse);
      });

      test('handles empty json', () {
        final json = <String, dynamic>{};

        final model = IamportResultModel.fromJson(json);

        expect(model.impUid, isNull);
        expect(model.merchantUid, isNull);
        expect(model.success, isFalse);
        expect(model.errorMsg, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const model = IamportResultModel(
          impUid: 'imp_abc',
          merchantUid: 'mid_xyz',
          success: true,
          pgProvider: 'danal',
          pgType: 'certification',
        );

        final json = model.toJson();

        expect(json['imp_uid'], 'imp_abc');
        expect(json['merchant_uid'], 'mid_xyz');
        expect(json['success'], isTrue);
        expect(json['error_msg'], isNull);
        expect(json['pg_provider'], 'danal');
        expect(json['pg_type'], 'certification');
      });

      test('roundtrip fromJson/toJson preserves data', () {
        const original = IamportResultModel(
          impUid: 'imp_roundtrip',
          merchantUid: 'mid_roundtrip',
          success: true,
          pgProvider: 'nice',
          pgType: 'payment',
        );

        final restored = IamportResultModel.fromJson(original.toJson());

        expect(restored, original);
      });
    });

    group('fromMap', () {
      test('parses string map with success=true', () {
        final map = <String, String>{
          'imp_uid': 'imp_map_001',
          'merchant_uid': 'mid_map_001',
          'success': 'true',
          'error_msg': '',
          'pg_provider': 'danal',
          'pg_type': 'certification',
        };

        final model = IamportResultModel.fromMap(map);

        expect(model.impUid, 'imp_map_001');
        expect(model.merchantUid, 'mid_map_001');
        expect(model.success, isTrue);
      });

      test('parses string map with success=True (capitalized)', () {
        final map = <String, String>{
          'imp_uid': 'imp_map_002',
          'merchant_uid': 'mid_map_002',
          'success': 'True',
        };

        final model = IamportResultModel.fromMap(map);

        expect(model.success, isTrue);
      });

      test('parses string map with success=false', () {
        final map = <String, String>{
          'imp_uid': '',
          'merchant_uid': 'mid_map_003',
          'success': 'false',
          'error_msg': 'Certification cancelled',
        };

        final model = IamportResultModel.fromMap(map);

        expect(model.success, isFalse);
        expect(model.errorMsg, 'Certification cancelled');
      });

      test('treats missing success key as false', () {
        final map = <String, String>{
          'imp_uid': 'imp_map_004',
          'merchant_uid': 'mid_map_004',
        };

        final model = IamportResultModel.fromMap(map);

        expect(model.success, isFalse);
      });

      test('treats arbitrary success value as false', () {
        final map = <String, String>{
          'success': 'yes',
        };

        final model = IamportResultModel.fromMap(map);

        expect(model.success, isFalse);
      });
    });

    group('equality', () {
      test('two models with same values are equal', () {
        const a = IamportResultModel(
          impUid: 'imp_eq',
          merchantUid: 'mid_eq',
          success: true,
        );
        const b = IamportResultModel(
          impUid: 'imp_eq',
          merchantUid: 'mid_eq',
          success: true,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('two models with different values are not equal', () {
        const a = IamportResultModel(impUid: 'imp_1', success: true);
        const b = IamportResultModel(impUid: 'imp_2', success: true);

        expect(a, isNot(b));
      });
    });

    group('copyWith', () {
      test('creates modified copy', () {
        const original = IamportResultModel(
          impUid: 'imp_copy',
          errorMsg: 'timeout',
        );

        final modified = original.copyWith(success: true, errorMsg: null);

        expect(modified.impUid, 'imp_copy');
        expect(modified.success, isTrue);
        expect(modified.errorMsg, isNull);
      });
    });
  });
}
