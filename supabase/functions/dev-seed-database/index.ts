import { createClient } from '@supabase/supabase-js'

// ─── Guard Clause ───────────────────────────────────────────
// Block execution in production (Deno Deploy sets DENO_DEPLOYMENT_ID)
function isProduction(): boolean {
  return !!Deno.env.get('DENO_DEPLOYMENT_ID')
}

// ─── User Persona Generation (20 users) ─────────────────────
// Ported from Dart: tests/test_data_seeder/lib/seeder_users.dart
// Original generates 124+ users (ages 20-50). This version generates 20 users (ages 20-24).
interface UserPersona {
  email: string
  password: string
  metadata: {
    name: string
    username: string
    gender: string
    birth_date: string
    phone_number: string
    is_verified: boolean
  }
}

function generatePersonas(): UserPersona[] {
  const currentYear = new Date().getFullYear()
  const personas: UserPersona[] = []
  const password = 'password1234!'

  // Ages 20-24 only (5 ages × 4 personas = 20 users)
  for (let age = 20; age <= 24; age++) {
    const birthYear = currentYear - age + 1
    const birthDate = `${birthYear}-01-01`

    const variants = [
      { gender: 'male', verified: true, suffix: '인증O' },
      { gender: 'male', verified: false, suffix: '인증X' },
      { gender: 'female', verified: true, suffix: '인증O' },
      { gender: 'female', verified: false, suffix: '인증X' },
    ]

    for (const v of variants) {
      const genderKr = v.gender === 'male' ? '남' : '여'
      const genderShort = v.gender === 'male' ? 'm' : 'f'
      const verifShort = v.verified ? 'ok' : 'no'

      const name = `${age}${genderKr}_${v.suffix}`
      const username = `user_${age}_${genderShort}_${verifShort}`
      const email = `${username}@test.com`
      const last4 = `${v.verified ? '1' : '0'}${v.gender === 'male' ? '1' : '2'}00`
      const phoneNumber = `010-${1000 + age}-${last4}`

      personas.push({
        email,
        password,
        metadata: { name, username, gender: v.gender, birth_date: birthDate, phone_number: phoneNumber, is_verified: v.verified },
      })
    }
  }

  return personas
}

// ─── Create User with Delete-and-Retry ──────────────────────
// Ported from Dart: tests/test_data_seeder/lib/seeder_base.dart:129-170
async function createAdminUser(
  supabase: ReturnType<typeof createClient>,
  persona: UserPersona,
): Promise<string> {
  const { data, error } = await supabase.auth.admin.createUser({
    email: persona.email,
    password: persona.password,
    email_confirm: true,
    user_metadata: persona.metadata,
  })

  if (error) {
    if (error.message?.includes('already registered') || (error as any).code === 'email_exists') {
      // Delete existing and retry
      const { data: users } = await supabase.auth.admin.listUsers({ perPage: 1000 })
      const existing = users?.users?.find((u: any) => u.email === persona.email)
      if (existing) {
        await supabase.auth.admin.deleteUser(existing.id)
      }
      return createAdminUser(supabase, persona)
    }
    throw error
  }

  return data.user?.id ?? ''
}

// ─── Main Handler ───────────────────────────────────────────
Deno.serve(async (_req) => {
  if (isProduction()) {
    return new Response(
      JSON.stringify({ error: 'Dev-only function. Blocked in production.' }),
      { status: 403, headers: { 'Content-Type': 'application/json' } },
    )
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    const personas = generatePersonas()
    let createdCount = 0

    for (const persona of personas) {
      try {
        await createAdminUser(supabase, persona)
        createdCount++
      } catch (err) {
        console.error(`Failed to create ${persona.email}:`, err)
      }
    }

    return new Response(
      JSON.stringify({ created_users: createdCount, total_requested: personas.length }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
