// _shared/_testing/fixtures/user.ts — user_profiles row builder

export interface UserProfileFixture {
  id: string;
  is_verified: boolean;
  gender: string | null;
  birth_date: string | null;
}

const DEFAULTS: UserProfileFixture = {
  id: "u-1",
  is_verified: true,
  gender: "male",
  birth_date: "1990-01-01",
};

export function buildUserProfile(overrides: Partial<UserProfileFixture> = {}): UserProfileFixture {
  return { ...DEFAULTS, ...overrides };
}
