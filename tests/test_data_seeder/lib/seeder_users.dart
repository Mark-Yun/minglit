part of 'database_seeder.dart';

mixin SeederUsers on _SeederContext, SeederBase {
  /// Generates 124+ detailed user personas for testing diverse scenarios.
  ///
  /// Scenarios:
  /// - Ages: 20-50 (31 ages)
  /// - Gender: Male (2), Female (2) per age
  /// - Status: Verified vs Unverified
  Future<void> _seedPersonas() async {
    _Log.i('👥 Step 1: Seeding 124+ Persona Users...');

    final currentYear = DateTime.now().year;

    // 1. Standard Personas: Age 20 ~ 50 (31 years)
    for (var age = 20; age <= 50; age++) {
      final birthYear = currentYear - age + 1; // Korean age roughly
      final birthDate = '$birthYear-01-01';

      // 4 Personas per age
      final personas = [
        {'gender': 'male', 'verified': true, 'suffix': '인증O'},
        {'gender': 'male', 'verified': false, 'suffix': '인증X'},
        {'gender': 'female', 'verified': true, 'suffix': '인증O'},
        {'gender': 'female', 'verified': false, 'suffix': '인증X'},
      ];

      for (final p in personas) {
        final gender = p['gender'] as String;
        final verified = p['verified'] as bool;
        final suffix = p['suffix'] as String;
        final genderKr = gender == 'male' ? '남' : '여';
        final genderShort = gender == 'male' ? 'm' : 'f';
        final verifShort = verified ? 'ok' : 'no';

        final name = '${age}${genderKr}_$suffix';
        final username = 'user_${age}_${genderShort}_$verifShort';
        final email = '$username@test.com';

        // Unique phone number logic:
        // Middle: 1000 + age (e.g., 1020)
        // Last:
        //  - Verified (1) / Unverified (0)
        //  - Male (1) / Female (2)
        //  - 00 (padding)
        final last4 =
            '${verified ? "1" : "0"}${gender == "male" ? "1" : "2"}00';

        final metadata = <String, dynamic>{
          'name': name,
          'username': username,
          'gender': gender,
          'birth_date': birthDate,
          'phone_number': '010-${1000 + age}-$last4',
          'is_verified': verified, // Custom flag for easy check
        };

        await _createAdminUser(
          email: email,
          password: 'password1234!',
          metadata: metadata,
        );
      }
    }

    // 2. Edge Case Personas
    // No profile image, no bio, etc.
    final edgeCases = [
      {
        'name': '40남_정보누락',
        'username': 'user_40_m_incomplete',
        'gender': 'male',
        'age': 40,
        'verified': false,
      },
      {
        'name': '25여_프로필없음',
        'username': 'user_25_f_noprofile',
        'gender': 'female',
        'age': 25,
        'verified': true,
      },
    ];

    for (final ec in edgeCases) {
      final age = ec['age'] as int;
      final birthYear = currentYear - age + 1;
      final metadata = <String, dynamic>{
        'name': ec['name'],
        'username': ec['username'],
        'gender': ec['gender'],
        'birth_date': '$birthYear-01-01',
        'phone_number': '010-9999-${age + 1000}',
      };

      await _createAdminUser(
        email: '${ec['username']}@test.com',
        password: 'password1234!',
        metadata: metadata,
      );
    }
  }
}
