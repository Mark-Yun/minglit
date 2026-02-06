import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
Future<UserProfile?> currentUserProfile(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('user_profiles')
      .select()
      .eq('id', user.id)
      .single();

  return UserProfile.fromJson(data);
}
