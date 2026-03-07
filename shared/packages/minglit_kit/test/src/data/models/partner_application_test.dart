import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/partner_application.dart';

void main() {
  group('PartnerApplication', () {
    Map<String, dynamic> appJson() => {
      'id': 'app_1',
      'user_id': 'user_1',
      'brand_name': 'Minglit Lounge',
      'introduction': 'Best social lounge in Gangnam',
      'address': '서울시 강남구',
      'contact_phone': '010-1234-5678',
      'contact_email': 'test@minglit.com',
      'biz_type': '법인사업자',
      'biz_name': '(주)밍글릿',
      'biz_number': '123-45-67890',
      'representative_name': '김밍글',
      'bank_name': '신한은행',
      'account_number': '110-123-456789',
      'account_holder': '김밍글',
      'biz_registration_path': 'user_1/biz_reg_123.pdf',
      'bankbook_path': 'user_1/bankbook_456.jpg',
      'status': 'pending',
      'admin_comment': null,
      'created_at': '2026-01-15T12:00:00.000',
      'updated_at': '2026-01-15T12:00:00.000',
    };

    test('creates from JSON with all fields', () {
      final app = PartnerApplication.fromJson(appJson());

      expect(app.id, 'app_1');
      expect(app.userId, 'user_1');
      expect(app.brandName, 'Minglit Lounge');
      expect(app.introduction, 'Best social lounge in Gangnam');
      expect(app.address, '서울시 강남구');
      expect(app.contactPhone, '010-1234-5678');
      expect(app.contactEmail, 'test@minglit.com');
      expect(app.bizType, '법인사업자');
      expect(app.bizName, '(주)밍글릿');
      expect(app.bizNumber, '123-45-67890');
      expect(app.representativeName, '김밍글');
      expect(app.bankName, '신한은행');
      expect(app.accountNumber, '110-123-456789');
      expect(app.accountHolder, '김밍글');
      expect(app.bizRegistrationPath, 'user_1/biz_reg_123.pdf');
      expect(app.bankbookPath, 'user_1/bankbook_456.jpg');
      expect(app.status, 'pending');
      expect(app.adminComment, isNull);
    });

    test('defaults status to draft', () {
      final json = appJson()..remove('status');
      final app = PartnerApplication.fromJson(json);
      expect(app.status, 'draft');
    });

    test('serializes to JSON and back', () {
      final original = PartnerApplication.fromJson(appJson());
      final json = original.toJson();
      final restored = PartnerApplication.fromJson(json);

      expect(restored, equals(original));
    });

    test('toDbJson removes id and timestamps', () {
      final app = PartnerApplication.fromJson(appJson());
      final dbJson = app.toDbJson();

      expect(dbJson.containsKey('id'), isFalse);
      expect(dbJson.containsKey('created_at'), isFalse);
      expect(dbJson.containsKey('updated_at'), isFalse);
      expect(dbJson.containsKey('user_id'), isTrue);
      expect(dbJson.containsKey('brand_name'), isTrue);
      expect(dbJson.containsKey('biz_number'), isTrue);
    });

    test('copyWith creates modified copy', () {
      final app = PartnerApplication.fromJson(appJson());
      final approved = app.copyWith(
        status: 'approved',
        adminComment: 'Looks good!',
      );

      expect(approved.status, 'approved');
      expect(approved.adminComment, 'Looks good!');
      expect(approved.id, 'app_1');
      expect(approved.brandName, 'Minglit Lounge');
    });

    test('equality works with same values', () {
      final a1 = PartnerApplication.fromJson(appJson());
      final a2 = PartnerApplication.fromJson(appJson());
      expect(a1, equals(a2));
    });

    test('inequality with different values', () {
      final a1 = PartnerApplication.fromJson(appJson());
      final a2 = PartnerApplication.fromJson({
        ...appJson(),
        'id': 'app_2',
      });
      expect(a1, isNot(equals(a2)));
    });
  });
}
