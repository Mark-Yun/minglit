import 'package:supabase/supabase.dart';

/// Finds a Male user, Age 25 (approx), Verified.
Future<String> getMale25VerifiedUserId(SupabaseClient client) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;
  final res = await client
      .from('user_profiles')
      .select('id')
      .eq('gender', 'male')
      .eq('birth_date', '$targetBirthYear-01-01')
      .like('username', '%_ok')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    throw Exception(
        '🚨 Helper Error: Male/25/Verified user not found. Run seeder?');
  }
  return res['id'] as String;
}

/// Finds a Female user, Age 25 (approx), Verified.
Future<String> getFemale25VerifiedUserId(SupabaseClient client) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;
  final res = await client
      .from('user_profiles')
      .select('id')
      .eq('gender', 'female')
      .eq('birth_date', '$targetBirthYear-01-01')
      .like('username', '%_ok')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    throw Exception(
        '🚨 Helper Error: Female/25/Verified user not found. Run seeder?');
  }
  return res['id'] as String;
}
