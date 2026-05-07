import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    final now = DateTime(2026, 1, 15, 12);

    Map<String, dynamic> profileJson() => {
      'id': 'user_1',
      'name': '김밍글',
      'username': 'mingle_kim',
      'phone_number': '010-1234-5678',
      'gender': 'male',
      'birth_date': now.toIso8601String(),
      'is_verified': true,
      'birth_year': 1995,
      'avatar_url': 'https://img.com/avatar.jpg',
      'profile_image_url': 'https://img.com/profile.jpg',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('creates from JSON with all fields', () {
      final profile = UserProfile.fromJson(profileJson());

      expect(profile.id, 'user_1');
      expect(profile.name, '김밍글');
      expect(profile.username, 'mingle_kim');
      expect(profile.phoneNumber, '010-1234-5678');
      expect(profile.gender, 'male');
      expect(profile.isVerified, isTrue);
      expect(profile.birthYear, 1995);
      expect(profile.avatarUrl, 'https://img.com/avatar.jpg');
      expect(profile.profileImageUrl, 'https://img.com/profile.jpg');
    });

    test('creates with minimal fields and defaults', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'name': 'Test',
        'username': 'test',
      });

      expect(profile.phoneNumber, isNull);
      expect(profile.gender, isNull);
      expect(profile.birthDate, isNull);
      expect(profile.isVerified, isFalse);
      expect(profile.birthYear, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.profileImageUrl, isNull);
    });

    test('serializes to JSON and back', () {
      final original = UserProfile.fromJson(profileJson());
      final json = original.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored, equals(original));
    });

    test('copyWith creates modified copy', () {
      final profile = UserProfile.fromJson(profileJson());
      final modified = profile.copyWith(
        name: '이밍글',
        isVerified: false,
      );

      expect(modified.name, '이밍글');
      expect(modified.isVerified, isFalse);
      expect(modified.id, 'user_1');
    });

    test('equality works', () {
      final p1 = UserProfile.fromJson(profileJson());
      final p2 = UserProfile.fromJson(profileJson());
      expect(p1, equals(p2));
    });

    test('inequality with different values', () {
      final p1 = UserProfile.fromJson(profileJson());
      final p2 = UserProfile.fromJson({...profileJson(), 'id': 'user_2'});
      expect(p1, isNot(equals(p2)));
    });

    // Fix #2250: partner_visible_user_profiles view omits name (실명) column.
    // UserProfile.fromJson() must not throw when name is absent — runtime crash
    // on getApplicationById() would make the entire detail page fail to load.
    test('fromJson without name field defaults to empty string', () {
      final profile = UserProfile.fromJson({
        'id': 'u1',
        'username': '닉네임123',
        'birth_year': 1995,
        'is_verified': true,
        'profile_image_url': null,
      });

      expect(profile.name, '');
      expect(profile.username, '닉네임123');
      expect(profile.birthYear, 1995);
      expect(profile.isVerified, isTrue);
    });

    // Fix #2250: simulates the exact JSON shape returned by PostgREST when
    // getApplicationById() embeds user:partner_visible_user_profiles(...).
    // If this test passes, the partner application detail page will load without crash.
    test('fromJson with partner_visible_user_profiles view shape', () {
      // Mirrors the PostgREST response for:
      // .select('*, user:partner_visible_user_profiles(id, username, birth_year,
      //          is_verified, profile_image_url)')
      final viewJson = {
        'id': 'user_abc',
        'username': '파트너뷰닉네임',
        'birth_year': 1990,
        'is_verified': false,
        'profile_image_url': 'https://example.com/img.jpg',
        // name, phone_number, gender, birth_date intentionally absent (view-restricted)
      };

      expect(() => UserProfile.fromJson(viewJson), returnsNormally);
      final profile = UserProfile.fromJson(viewJson);
      expect(profile.name, '');
      expect(profile.birthYear, 1990);
      expect(profile.birthDate, isNull);
      expect(profile.phoneNumber, isNull);
      expect(profile.gender, isNull);
    });

    test('JSON contains expected keys', () {
      final profile = UserProfile.fromJson(profileJson());
      final json = profile.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('username'), isTrue);
      expect(json.containsKey('phone_number'), isTrue);
      expect(json.containsKey('is_verified'), isTrue);
      expect(json.containsKey('birth_year'), isTrue);
    });
  });
}
