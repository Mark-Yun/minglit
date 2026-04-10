import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Core Mocks ---
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

// --- Repository Mocks ---
class MockEventRepository extends Mock implements EventRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockVerificationRepository extends Mock
    implements VerificationRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockPartyRepository extends Mock implements PartyRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

class MockStorageRepository extends Mock implements StorageRepository {}

class MockSocialRepository extends Mock implements SocialRepository {}

class MockMatchingRepository extends Mock implements MatchingRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

class MockTagRepository extends Mock implements TagRepository {}

// --- Model Mocks (Optional, usually better to use real models) ---
// But sometimes we need to mock complex objects
class MockUser extends Mock implements User {}

class MockUserProfile extends Mock implements UserProfile {}

class MockEvent extends Mock implements Event {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}
