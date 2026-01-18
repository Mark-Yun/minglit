import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/data/repositories/user_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Core Mocks ---
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

// --- Repository Mocks ---
class MockEventRepository extends Mock implements EventRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockIdentityRepository extends Mock implements IdentityRepository {}
class MockVerificationRepository extends Mock implements VerificationRepository {}
class MockUserRepository extends Mock implements UserRepository {}

// --- Model Mocks (Optional, usually better to use real models) ---
// But sometimes we need to mock complex objects
class MockUser extends Mock implements User {}
class MockUserProfile extends Mock implements UserProfile {}
class MockEvent extends Mock implements Event {}
