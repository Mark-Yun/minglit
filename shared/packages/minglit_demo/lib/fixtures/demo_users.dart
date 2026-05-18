/// User-domain fixtures: Supabase `User`, `UserProfile`, `UserConsent`,
/// `UserSettings`. Single demo user for "auto-logged-in" boot state.
///
/// Owned by **P1-1 agent**. See task #11.
///
/// Required exports:
///   - `Supabase User demoUser` — for `currentUserProvider` override
///   - `UserProfile demoUserProfile` — for `currentUserProfileProvider`
///   - `List<UserConsent> demoUserConsents` — for ConsentRepository
///   - `UserSettings demoUserSettings` — for settings screens
///
/// Constraints:
///   - All fields realistic-looking (Korean names, plausible birthdate)
///   - "Fully provisioned": consent complete, onboarding complete, verified
///   - User ID matches `demoWorld.userId` (see demo_world.dart)
library;

import 'package:minglit_kit/minglit_data.dart';

import 'demo_world.dart';

/// The auto-logged-in demo user (Supabase auth side).
///
/// Constructed via the `const` constructor — no Supabase SDK call needed.
/// All date strings use ISO-8601 format as expected by gotrue internals.
const User demoUser = User(
  id: DemoWorld.userId,
  aud: 'authenticated',
  email: DemoWorld.userEmail,
  phone: DemoWorld.userPhone,
  role: 'authenticated',
  createdAt: '2025-01-10T09:00:00.000Z',
  emailConfirmedAt: '2025-01-10T09:00:05.000Z',
  lastSignInAt: '2026-05-18T19:00:00.000Z',
  updatedAt: '2026-05-18T19:00:00.000Z',
  appMetadata: <String, dynamic>{
    'provider': 'kakao',
    'providers': <String>['kakao'],
  },
  userMetadata: <String, dynamic>{
    'full_name': '김민글',
    'email': DemoWorld.userEmail,
  },
  isAnonymous: false,
);

/// Full profile (UserProfile from minglit_kit).
///
/// Fully provisioned: isVerified=true, birthDate set, all router guards pass.
final UserProfile demoUserProfile = UserProfile(
  id: DemoWorld.userId,
  name: '김민글',
  username: 'mingeul_kim',
  phoneNumber: DemoWorld.userPhone,
  gender: 'male',
  birthDate: DateTime.utc(1995, 8, 20),
  birthYear: 1995,
  isVerified: true,
  avatarUrl: null,
  profileImageUrl: null,
  createdAt: DateTime.utc(2025, 1, 10, 9, 0, 0),
  updatedAt: DemoWorld.now,
);

/// User consents — all required types agreed, plus optional marketing/location.
///
/// Required types: termsOfService, privacyCollection, ageConfirmation.
/// Optional included: marketingConsent, locationConsent.
/// Omitted: thirdPartyProvision (user chose not to agree — valid optional).
final List<UserConsent> demoUserConsents = [
  UserConsent(
    id: '00000000-0000-4000-9000-000000000001',
    userId: DemoWorld.userId,
    consentKey: ConsentType.termsOfService,
    consented: true,
    consentedAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    createdAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    policyVersion: 1,
  ),
  UserConsent(
    id: '00000000-0000-4000-9000-000000000002',
    userId: DemoWorld.userId,
    consentKey: ConsentType.privacyCollection,
    consented: true,
    consentedAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    createdAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    policyVersion: 1,
  ),
  UserConsent(
    id: '00000000-0000-4000-9000-000000000003',
    userId: DemoWorld.userId,
    consentKey: ConsentType.ageConfirmation,
    consented: true,
    consentedAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    createdAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    policyVersion: 1,
  ),
  UserConsent(
    id: '00000000-0000-4000-9000-000000000004',
    userId: DemoWorld.userId,
    consentKey: ConsentType.marketingConsent,
    consented: true,
    consentedAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    createdAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    policyVersion: 1,
  ),
  UserConsent(
    id: '00000000-0000-4000-9000-000000000005',
    userId: DemoWorld.userId,
    consentKey: ConsentType.locationConsent,
    consented: true,
    consentedAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    createdAt: DateTime.utc(2025, 1, 10, 9, 1, 0),
    policyVersion: 1,
  ),
];

/// User settings.
final UserSettings demoUserSettings = UserSettings(
  userId: DemoWorld.userId,
  updatedAt: DemoWorld.now,
  marketingConsent: true,
  serviceNotification: true,
);
