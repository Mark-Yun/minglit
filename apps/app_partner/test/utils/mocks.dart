import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

// --- Core Mocks ---
class MockGoRouter extends Mock implements GoRouter {}

// --- Repository Mocks ---
class MockEventRepository extends Mock implements EventRepository {}

class MockPartnerRepository extends Mock implements PartnerRepository {}

class MockPartyRepository extends Mock implements PartyRepository {}

class MockTicketRepository extends Mock implements TicketRepository {}

class MockLocationRepository extends Mock implements LocationRepository {}

class MockVerificationRepository extends Mock
    implements VerificationRepository {}

class MockUserRepository extends Mock implements UserRepository {}
