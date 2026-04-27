import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
// Fix #1948: use UserRepository instead of direct Supabase — adds error handling,
// PGRST116 → null, and a proper test seam.
Future<UserProfile?> currentUserProfile(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.read(userRepositoryProvider);
  return repo.getUserProfile(user.id);
}
