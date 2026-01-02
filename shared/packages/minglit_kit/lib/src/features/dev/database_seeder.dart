import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// **Database Seeder (Refactored)**
///
/// Handles programmatic data seeding for local development using Models.
class DatabaseSeeder {
  DatabaseSeeder(this._adminClient);

  final SupabaseClient _adminClient;

  /// Runs the full seeding process.
  Future<void> seed() async {
    Log.i('🌱 [Seeder] Starting Fresh Seeding...');

    try {
      // 1. Create Global Verifications
      final globalVerifIds = await _seedGlobalVerifications();
      Log.i('✅ Global Verifications Created: ${globalVerifIds.length} items');

      // 2. Create Normal Users
      await _seedUsers();

      // 3. Create Partners & Their Members
      await _seedPartners(globalVerifIds);

      Log.i('✅ [Seeder] Seeding Completed!');
    } catch (e, st) {
      Log.e('🔥 [Seeder] Seeding Failed', e, st);
      rethrow;
    }
  }

  Future<List<String>> _seedGlobalVerifications() async {
    Log.i('📜 Step 0: Seeding Global Verifications...');

    // We can use the Verification model if available, but simple maps are fine
    // for structure defs
    final result = await _adminClient
        .from('verifications')
        .insert([
          {
            'category': 'career',
            'internal_name': 'Global Career Verification',
            'display_name': '직장 인증',
            'description': '회사 이메일 또는 재직증명서로 인증하세요.',
            'icon_key': 'briefcase',
            'form_schema': [
              {
                'key': 'company_name',
                'type': 'text',
                'label': '회사명',
                'required': true,
              },
              {
                'key': 'proof_doc',
                'type': 'file',
                'label': '재직증명서/명함',
                'required': true,
              },
            ],
            'partner_id': null, // Global
          },
          {
            'category': 'academic',
            'internal_name': 'Global Academic Verification',
            'display_name': '학력 인증',
            'description': '졸업증명서로 학력을 인증하세요.',
            'icon_key': 'school',
            'form_schema': [
              {
                'key': 'univ_name',
                'type': 'text',
                'label': '학교명',
                'required': true,
              },
              {
                'key': 'major',
                'type': 'text',
                'label': '전공',
                'required': true,
              },
              {
                'key': 'proof_doc',
                'type': 'file',
                'label': '졸업증명서',
                'required': true,
              },
            ],
            'partner_id': null, // Global
          },
        ])
        .select('id');

    return (result as List)
        .map((dynamic e) => (e as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Future<void> _seedUsers() async {
    Log.i('👥 Step 1: Seeding 100 Normal Users...');
    for (var i = 1; i <= 100; i++) {
      final metadata = <String, dynamic>{
        'name': 'User $i',
        'username': 'user_$i', // username은 식별을 위해 항상 포함
      };

      // 50번 미만 유저만 상세 정보(인증 상태 가정) 포함
      if (i < 50) {
        metadata['username'] = 'user_$i';
        metadata['gender'] = i.isOdd ? 'male' : 'female';
        metadata['phone_number'] = '010-${1000 + i}-${2000 + i}';
      }

      await _createAdminUser(
        email: 'user$i@test.com',
        password: 'password',
        metadata: metadata,
      );
    }
  }

  Future<void> _seedPartners(List<String> globalVerifIds) async {
    Log.i('🏢 Step 2: Seeding 10 Partners & Staffs...');
    for (var i = 1; i <= 10; i++) {
      final partnerName = 'Minglit Shop $i';

      // ... (Owner creation code remains same) ...
      // 1. Create Owner User
      final ownerId = await _createAdminUser(
        email: 'owner$i@test.com',
        password: 'password',
        metadata: {
          'name': 'Owner $i ($partnerName)',
          'username': 'owner_$i',
          'gender': 'male',
          'phone_number': '010-0000-${1000 + i}',
        },
      );

      // 2. Create Partner record
      final partnerRes = await _adminClient
          .from('partners')
          .insert({
            'name': partnerName,
            'introduction': 'Welcome to $partnerName! Best service guaranteed.',
            'biz_name': 'Biz $i',
            'biz_number': '123-45-${60000 + i}',
            'contact_email': 'owner$i@test.com',
          })
          .select('id')
          .single();
      final partnerId = partnerRes['id'] as String;

      // 3. Link Owner
      await _adminClient.from('partner_member_permissions').insert({
        'partner_id': partnerId,
        'user_id': ownerId,
        'role': 'owner',
      });

      // 4. Create 2 Staffs per partner
      for (var s = 1; s <= 2; s++) {
        final staffId = await _createAdminUser(
          email: 'staff$i-$s@test.com',
          password: 'password',
          metadata: {
            'name': 'Staff $i-$s ($partnerName)',
            'username': 'staff_${i}_$s',
            'gender': s.isOdd ? 'female' : 'male',
            'phone_number': '010-1111-${(i * 10) + s}',
          },
        );

        await _adminClient.from('partner_member_permissions').insert({
          'partner_id': partnerId,
          'user_id': staffId,
          'role': 'staff',
        });
      }

      // 5. Create 1 Location (Gangnam Station style) for each partner
      final locationRes = await _adminClient
          .from('locations')
          .insert({
            'partner_id': partnerId,
            'name': 'Gangnam Station Branch',
            'address': 'Seoul Gangnam-gu Gangnam-daero 396',
            'address_detail': 'Exit 11',
            'region_1': 'Seoul',
            'region_2': 'Gangnam-gu',
            'region_3': 'Yeoksam-dong',
            'geo_point': 'POINT(127.0276 37.4979)',
          })
          .select('id')
          .single();
      final locationId = locationRes['id'] as String;

      // 6. Create 1 Party linked to this location
      // Diverse Scenarios based on loop index
      List<Map<String, dynamic>> conditions;

      if (i % 3 == 1) {
        // Scenario A: Male(Job) vs Female(School)
        conditions = [
          {
            'id': const Uuid().v4(),
            'gender': 'male',
            'birth_year_range': {'min': 1990, 'max': 2000},
            'required_verification_ids':
                globalVerifIds.isNotEmpty ? [globalVerifIds[0]] : <String>[],
          },
          {
            'id': const Uuid().v4(),
            'gender': 'female',
            'birth_year_range': {'min': 1995, 'max': 2005},
            'required_verification_ids':
                globalVerifIds.length > 1 ? [globalVerifIds[1]] : <String>[],
          },
        ];
      } else if (i % 3 == 2) {
        // Scenario B: Anyone + Job Verification
        conditions = [
          {
            'id': const Uuid().v4(),
            'gender': null, // Anyone
            'birth_year_range': null, // Any age
            'required_verification_ids':
                globalVerifIds.isNotEmpty ? [globalVerifIds[0]] : <String>[],
          }
        ];
      } else {
        // Scenario C: 20s Only + No Verification
        conditions = [
          {
            'id': const Uuid().v4(),
            'gender': null,
            'birth_year_range': {'min': 1995, 'max': 2004},
            'required_verification_ids': <String>[],
          }
        ];
      }

      await _adminClient.from('parties').insert({
        'partner_id': partnerId,
        'location_id': locationId,
        'title': '$partnerName Party (Type ${i % 3})',
        'description': {
          'ops': [
            {'insert': "Let's drink wine!\n"},
          ],
        },
        'min_confirmed_count': 5,
        'max_participants': 20,
        'status': 'active',
        'conditions': conditions,
        // Legacy field kept for compatibility or removed if schema changed
        'required_verification_ids': <String>[],
      });
    }
  }

  /// Creates a user via Supabase Admin API.
  /// Deletes existing user if email is already taken for a clean start.
  Future<String> _createAdminUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final res = await _adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: metadata,
        ),
      );
      return res.user!.id;
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.code == 'email_exists') {
        // Cleanup and retry
        try {
          // Attempt to find user with pagination (up to 1000 users)
          final usersRes = await _adminClient.auth.admin.listUsers(
            perPage: 1000,
          );

          try {
            final existing = usersRes.firstWhere((u) => u.email == email);
            await _adminClient.auth.admin.deleteUser(existing.id);
            Log.i('♻️ Deleted existing user: $email');
          } catch (_) {
            // User not found in list, but create failed?
            // This is a weird edge case. Just return null or rethrow.
            Log.w(
              '''⚠️ User $email creation failed but could not find in list to delete.''',
            );
            rethrow;
          }

          // Retry creation
          return _createAdminUser(
            email: email,
            password: password,
            metadata: metadata,
          );
        } catch (cleanupError) {
          Log.e('❌ Cleanup failed for $email', cleanupError);
          rethrow;
        }
      }
      rethrow;
    }
  }
}
