import { createClient, SupabaseClient } from '@supabase/supabase-js'

function isProduction(): boolean {
  const env = Deno.env.get('ENVIRONMENT')
  return env !== 'local' && env !== 'development'
}

const SEED_PASSWORD = 'password1234!'

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

const HOT_PLACES = [
  { name: '서울 강남', address: '서울특별시 강남구 역삼동', lat: 37.4979, lng: 127.0276, region_1: '서울', region_2: '강남구', region_3: '역삼동' },
  { name: '서울 홍대', address: '서울특별시 마포구 서교동', lat: 37.5575, lng: 126.9245, region_1: '서울', region_2: '마포구', region_3: '서교동' },
  { name: '서울 성수', address: '서울특별시 성동구 성수동', lat: 37.5445, lng: 127.0559, region_1: '서울', region_2: '성동구', region_3: '성수동' },
] as const

const SCENARIOS: {
  title: string
  summary: string
  minConfirmed: number
  maxParticipants: number
  verificationCategory: 'career' | 'academic' | 'asset' | null
  entryGroups: { label: string; gender: 'male' | 'female'; birthYearMin: number; birthYearMax: number }[]
  tickets: { name: string; price: number; quantity: number }[]
  metadata: { show_participant_list: boolean; visibility: string }
}[] = [
  {
    title: '대학생 소셜 밍글',
    summary: '같은 또래 대학생들이 모여 자연스럽게 네트워킹하는 자리',
    minConfirmed: 4,
    maxParticipants: 10,
    verificationCategory: 'academic',
    entryGroups: [
      { label: '남성', gender: 'male', birthYearMin: 2001, birthYearMax: 2005 },
      { label: '여성', gender: 'female', birthYearMin: 2001, birthYearMax: 2005 },
    ],
    tickets: [
      { name: '일반 티켓', price: 15000, quantity: 5 },
      { name: '얼리버드', price: 10000, quantity: 5 },
    ],
    metadata: { show_participant_list: true, visibility: 'public' },
  },
  {
    title: '직장인 금요 밍글',
    summary: '퇴근 후 가볍게 즐기는 직장인 소셜 파티',
    minConfirmed: 6,
    maxParticipants: 16,
    verificationCategory: 'career',
    entryGroups: [
      { label: '남성', gender: 'male', birthYearMin: 1995, birthYearMax: 2002 },
      { label: '여성', gender: 'female', birthYearMin: 1995, birthYearMax: 2002 },
    ],
    tickets: [
      { name: '스탠다드', price: 25000, quantity: 8 },
      { name: '프리미엄 (음료 포함)', price: 35000, quantity: 8 },
    ],
    metadata: { show_participant_list: true, visibility: 'public' },
  },
  {
    title: '프리미엄 라운지 밍글',
    summary: '검증된 멤버들만 참여하는 프리미엄 소셜 모임',
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategory: 'asset',
    entryGroups: [
      { label: '남성', gender: 'male', birthYearMin: 1990, birthYearMax: 2000 },
      { label: '여성', gender: 'female', birthYearMin: 1990, birthYearMax: 2000 },
    ],
    tickets: [
      { name: 'VIP 티켓', price: 50000, quantity: 4 },
      { name: 'VVIP 티켓 (디너 포함)', price: 80000, quantity: 4 },
    ],
    metadata: { show_participant_list: false, visibility: 'private' },
  },
  {
    title: '동네친구 보드게임',
    summary: '보드게임으로 시작하는 가벼운 동네 모임',
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategory: null,
    entryGroups: [
      { label: '참가자', gender: 'male', birthYearMin: 1995, birthYearMax: 2005 },
      { label: '참가자', gender: 'female', birthYearMin: 1995, birthYearMax: 2005 },
    ],
    tickets: [
      { name: '참가비', price: 10000, quantity: 8 },
    ],
    metadata: { show_participant_list: true, visibility: 'public' },
  },
  {
    title: '복합조건 네트워킹',
    summary: '다양한 배경의 사람들이 만나는 복합 네트워킹',
    minConfirmed: 6,
    maxParticipants: 12,
    verificationCategory: 'career',
    entryGroups: [
      { label: '남성 (20대)', gender: 'male', birthYearMin: 1999, birthYearMax: 2005 },
      { label: '여성 (20대)', gender: 'female', birthYearMin: 1999, birthYearMax: 2005 },
      { label: '남성 (30대)', gender: 'male', birthYearMin: 1990, birthYearMax: 1998 },
      { label: '여성 (30대)', gender: 'female', birthYearMin: 1990, birthYearMax: 1998 },
    ],
    tickets: [
      { name: '20대 티켓', price: 20000, quantity: 6 },
      { name: '30대 티켓', price: 25000, quantity: 6 },
    ],
    metadata: { show_participant_list: true, visibility: 'public' },
  },
  {
    title: '자유 오픈 밍글',
    summary: '누구나 참여 가능한 오픈 소셜 네트워킹',
    minConfirmed: 4,
    maxParticipants: 12,
    verificationCategory: null,
    entryGroups: [
      { label: '남성', gender: 'male', birthYearMin: 1990, birthYearMax: 2005 },
      { label: '여성', gender: 'female', birthYearMin: 1990, birthYearMax: 2005 },
    ],
    tickets: [{ name: '참가비', price: 12000, quantity: 12 }],
    metadata: { show_participant_list: true, visibility: 'public' },
  },
  {
    title: '직장인 애프터눈 라운지',
    summary: '직장인 인증 필수 — 오후의 여유로운 네트워킹',
    minConfirmed: 4,
    maxParticipants: 10,
    verificationCategory: 'career',
    entryGroups: [
      { label: '남성', gender: 'male', birthYearMin: 1988, birthYearMax: 2000 },
      { label: '여성', gender: 'female', birthYearMin: 1988, birthYearMax: 2000 },
    ],
    tickets: [{ name: '라운지 티켓', price: 20000, quantity: 10 }],
    metadata: { show_participant_list: true, visibility: 'public' },
  },
  {
    title: 'VIP 멤버십 파티',
    summary: '파트너 자체 인증 필수 — 엄선된 VIP 멤버십 파티',
    minConfirmed: 4,
    maxParticipants: 8,
    verificationCategory: 'asset',
    entryGroups: [
      { label: '남성 VIP', gender: 'male', birthYearMin: 1985, birthYearMax: 2000 },
      { label: '여성 VIP', gender: 'female', birthYearMin: 1985, birthYearMax: 2000 },
    ],
    tickets: [{ name: 'VIP 멤버십', price: 60000, quantity: 8 }],
    metadata: { show_participant_list: false, visibility: 'private' },
  },
]

const SEED_PARTNERS = [
  {
    name: '밍글 스튜디오',
    introduction: '서울 강남에서 운영하는 프리미엄 소셜 라운지',
    biz_name: '(주)밍글스튜디오',
    biz_number: '123-45-67890',
    contact_email: 'partner1@test.com',
    ownerEmail: 'partner_owner_1@test.com',
    location: HOT_PLACES[0],
    localVerifications: [
      { category: 'career' as const, internal_name: 'mingle_career', display_name: '직장인 인증', description: '재직증명서 또는 명함 제출', icon_key: 'briefcase', form_schema: [{ type: 'image', label: '재직증명서' }] },
      { category: 'academic' as const, internal_name: 'mingle_academic', display_name: '대학생 인증', description: '학생증 또는 재학증명서 제출', icon_key: 'school', form_schema: [{ type: 'image', label: '학생증' }] },
    ],
  },
  {
    name: '파티룸 홍대',
    introduction: '홍대에서 가장 힙한 파티룸. 다양한 테마의 소셜 이벤트를 운영합니다.',
    biz_name: '파티룸홍대',
    biz_number: '987-65-43210',
    contact_email: 'partner2@test.com',
    ownerEmail: 'partner_owner_2@test.com',
    location: HOT_PLACES[1],
    localVerifications: [
      { category: 'asset' as const, internal_name: 'hongdae_asset', display_name: '자산 인증', description: '프리미엄 파티 참가를 위한 자산 인증', icon_key: 'diamond', form_schema: [{ type: 'text', label: '자산 정보' }] },
    ],
  },
]

function generateDescription(title: string, summary: string): { ops: object[] } {
  return {
    ops: [
      { insert: `${title}\n`, attributes: { bold: true } },
      { insert: '\n' },
      { insert: `${summary}\n` },
      { insert: '\n' },
      { insert: '📍 장소 안내\n', attributes: { bold: true } },
      { insert: '이벤트 장소는 신청 확정 후 안내드립니다. 대중교통 이용을 권장합니다.\n' },
      { insert: '\n' },
      { insert: '✅ 참가 조건\n', attributes: { bold: true } },
      { insert: '본인 인증 완료 후 신청 가능합니다. 미성년자는 참여가 제한됩니다.\n' },
      { insert: '\n' },
      { insert: '🎁 포함 내용\n', attributes: { bold: true } },
      { insert: '음료 1잔 제공, 네트워킹 프로그램 진행, 기념 사진 촬영.\n' },
      { insert: '\n' },
      { insert: '⚠️ 주의사항\n', attributes: { bold: true } },
      { insert: '노쇼 시 패널티가 부과될 수 있습니다. 취소는 이벤트 24시간 전까지 가능합니다.\n' },
    ],
  }
}

function generatePersonas(): UserPersona[] {
  const currentYear = new Date().getFullYear()
  const personas: UserPersona[] = []
  const password = 'password1234!'

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

function generate30sPersonas(): UserPersona[] {
  const currentYear = new Date().getFullYear()
  const personas: UserPersona[] = []
  const password = 'password1234!'

  for (let age = 25; age <= 34; age++) {
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
      const phoneNumber = `010-${2000 + age}-${last4}`

      personas.push({
        email,
        password,
        metadata: { name, username, gender: v.gender, birth_date: birthDate, phone_number: phoneNumber, is_verified: v.verified },
      })
    }
  }

  return personas
}

function generateAllPersonas(): UserPersona[] {
  return [...generatePersonas(), ...generate30sPersonas()]
}

const GLOBAL_VERIFICATIONS = [
  { category: 'career', internal_name: 'global_career', display_name: '직장인 인증', description: '재직증명서 기반 직장인 인증', icon_key: 'briefcase', form_schema: [{ type: 'image', label: '재직증명서' }] },
  { category: 'academic', internal_name: 'global_academic', display_name: '대학생 인증', description: '학생증 기반 대학생 인증', icon_key: 'school', form_schema: [{ type: 'image', label: '학생증' }] },
  { category: 'asset', internal_name: 'global_asset', display_name: '자산 인증', description: '자산 보유 인증', icon_key: 'diamond', form_schema: [{ type: 'text', label: '자산 정보' }] },
]

// ALL_PARTNERS: SEED_PARTNERS + hot-place partners (merged for bulk RPC)
const ALL_PARTNERS = [
  ...SEED_PARTNERS,
  ...HOT_PLACES.map((place, idx) => ({
    name: `${place.name} 소셜클럽`,
    introduction: `${place.name} 지역 대표 소셜 클럽`,
    biz_name: `${place.name}클럽`,
    biz_number: `000-00-${String(idx).padStart(5, '0')}`,
    contact_email: `partner_hotplace_${idx}@test.com`,
    ownerEmail: `partner_hotplace_${idx}@test.com`,
    location: place,
    localVerifications: [] as { category: 'career' | 'academic' | 'asset'; internal_name: string; display_name: string; description: string; icon_key: string; form_schema: { type: string; label: string }[] }[],
  })),
]


async function createPartyWithEvents(
  sb: SupabaseClient,
  partnerId: string,
  locationId: string,
  scenario: typeof SCENARIOS[number],
  verificationIds: string[],
): Promise<{ partyId: string; eventIds: string[] }> {
  const { data: party, error: partyErr } = await sb.from('parties').insert({
    partner_id: partnerId,
    location_id: locationId,
    title: scenario.title,
    description: generateDescription(scenario.title, scenario.summary),
    image_urls: [],
    required_verification_ids: verificationIds,
    min_confirmed_count: scenario.minConfirmed,
    max_participants: scenario.maxParticipants,
    status: 'active',
    metadata: scenario.metadata,
  }).select('id').single()

  if (partyErr) throw new Error(`Failed to create party "${scenario.title}": ${partyErr.message}`)
  const partyId = party.id

  const templateIds: string[] = []
  for (const eg of scenario.entryGroups) {
    const { data: egt, error: egtErr } = await sb.from('entry_group_templates').insert({
      party_id: partyId,
      label: eg.label,
      gender: eg.gender,
      birth_year_min: eg.birthYearMin,
      birth_year_max: eg.birthYearMax,
      required_verification_ids: verificationIds,
    }).select('id').single()
    if (egtErr) throw new Error(`Failed to create entry_group_template: ${egtErr.message}`)
    templateIds.push(egt.id)
  }

  for (const ticket of scenario.tickets) {
    const { error: ttErr } = await sb.from('ticket_templates').insert({
      party_id: partyId,
      name: ticket.name,
      price: ticket.price,
      quantity: ticket.quantity,
      target_entry_group_ids: templateIds,
    })
    if (ttErr) throw new Error(`Failed to create ticket_template: ${ttErr.message}`)
  }

  const now = new Date()
  const eventIds: string[] = []

  for (let i = 0; i < 2; i++) {
    const startTime = new Date(now)
    startTime.setDate(now.getDate() + (i === 0 ? 3 : 10))
    startTime.setHours(19, 0, 0, 0)

    const endTime = new Date(startTime)
    endTime.setHours(22, 0, 0, 0)

    const { data: event, error: eventErr } = await sb.from('events').insert({
      party_id: partyId,
      location_id: locationId,
      start_time: startTime.toISOString(),
      end_time: endTime.toISOString(),
      min_confirmed_count: scenario.minConfirmed,
      max_participants: scenario.maxParticipants,
      status: 'scheduled',
      metadata: scenario.metadata,
    }).select('id').single()

    if (eventErr) throw new Error(`Failed to create event: ${eventErr.message}`)
    eventIds.push(event.id)

    const entryGroupIds: string[] = []
    for (const eg of scenario.entryGroups) {
      const { data: entryGroup, error: egErr } = await sb.from('entry_groups').insert({
        event_id: event.id,
        label: eg.label,
        gender: eg.gender,
        birth_year_min: eg.birthYearMin,
        birth_year_max: eg.birthYearMax,
        required_verification_ids: verificationIds,
      }).select('id').single()
      if (egErr) throw new Error(`Failed to create entry_group: ${egErr.message}`)
      entryGroupIds.push(entryGroup.id)
    }

    for (const ticket of scenario.tickets) {
      const { error: ticketErr } = await sb.from('tickets').insert({
        event_id: event.id,
        name: ticket.name,
        price: ticket.price,
        quantity: ticket.quantity,
        target_entry_group_ids: entryGroupIds,
        status: 'on_sale',
      })
      if (ticketErr) throw new Error(`Failed to create ticket: ${ticketErr.message}`)
    }
  }

  return { partyId, eventIds }
}

// ─── Domain Seeding Functions ───────────────────────────────────────

async function uploadSeedImages(supabase: SupabaseClient): Promise<string[]> {
  const imageFiles = ['party_cafe_warm.jpg', 'party_lounge_bright.jpg', 'party_premium_lounge.jpg']
  const urls: string[] = []

  // Check if images already exist in storage (uploaded externally or by a previous run)
  const { data: existing } = await supabase.storage.from('party-assets').list('seed-images', { limit: 10 })
  const existingNames = new Set((existing ?? []).map((f: { name: string }) => f.name))

  // If all images already exist, just return their public URLs
  const allExist = imageFiles.every(f => existingNames.has(f))
  if (allExist) {
    for (const filename of imageFiles) {
      const { data } = supabase.storage.from('party-assets').getPublicUrl(`seed-images/${filename}`)
      urls.push(data.publicUrl)
    }
    return urls
  }

  // Sign in as the first partner owner so storage trigger can set minglit_files.owner_id
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email: SEED_PARTNERS[0].ownerEmail,
    password: 'password1234!',
  })
  if (authError || !authData.session) {
    console.error('Failed to sign in as partner owner for image upload:', authError?.message)
    return urls
  }

  const authedClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${authData.session.access_token}` } },
  })

  for (const filename of imageFiles) {
    try {
      const fileUrl = new URL(`./assets/${filename}`, import.meta.url)
      const bytes = await Deno.readFile(fileUrl)
      const path = `seed-images/${filename}`

      const { error } = await authedClient.storage
        .from('party-assets')
        .upload(path, bytes, { contentType: 'image/jpeg', upsert: true })

      if (error) {
        console.error(`Failed to upload ${filename}:`, error.message)
        continue
      }

      const { data } = supabase.storage.from('party-assets').getPublicUrl(path)
      urls.push(data.publicUrl)
    } catch (err) {
      console.error(`Error uploading ${filename}:`, err)
    }
  }

  return urls
}

async function updatePartyImages(supabase: SupabaseClient, imageUrls: string[]): Promise<void> {
  if (imageUrls.length === 0) return

  const { data: parties } = await supabase.from('parties').select('id').order('created_at')
  if (!parties) return

  for (let i = 0; i < parties.length; i++) {
    const shuffled = [
      imageUrls[i % imageUrls.length],
      imageUrls[(i + 1) % imageUrls.length],
      imageUrls[(i + 2) % imageUrls.length],
    ]
    await supabase.from('parties').update({ image_urls: shuffled }).eq('id', parties[i].id)
  }
}

async function seedPartiesAndEvents(
  sb: SupabaseClient,
): Promise<{ createdParties: number; createdEvents: number }> {
  let createdParties = 0
  let createdEvents = 0

  // Fetch verifications to resolve IDs by category/internal_name
  const { data: verifications } = await sb.from('verifications').select('id, partner_id, category, internal_name')
  const verifByInternal: Record<string, string> = {}
  for (const v of verifications ?? []) {
    verifByInternal[v.internal_name] = v.id
  }

  // Seed defined partners: each gets 1 scenario
  for (const pDef of SEED_PARTNERS) {
    const { data: partner } = await sb.from('partners').select('id').eq('biz_number', pDef.biz_number).maybeSingle()
    if (!partner) continue

    const { data: location } = await sb.from('locations').select('id').eq('partner_id', partner.id).maybeSingle()
    if (!location) continue

    // Skip if party already exists for this partner
    const { data: existingParty } = await sb.from('parties').select('id').eq('partner_id', partner.id).maybeSingle()
    if (existingParty) continue

    const scenarioIdx = SEED_PARTNERS.indexOf(pDef)
    const scenario = SCENARIOS[scenarioIdx % SCENARIOS.length]
    const verifIds = scenario.verificationCategory
      ? [verifByInternal[`mingle_${scenario.verificationCategory}`] ?? verifByInternal[`global_${scenario.verificationCategory}`]].filter(Boolean)
      : []

    const { eventIds } = await createPartyWithEvents(sb, partner.id, location.id, scenario, verifIds)
    createdParties++
    createdEvents += eventIds.length
  }

  // Seed hot-place partners: each gets all scenarios
  for (let idx = 0; idx < HOT_PLACES.length; idx++) {
    const bizNumber = `000-00-${String(idx).padStart(5, '0')}`
    const { data: partner } = await sb.from('partners').select('id').eq('biz_number', bizNumber).maybeSingle()
    if (!partner) continue

    const { data: location } = await sb.from('locations').select('id').eq('partner_id', partner.id).maybeSingle()
    if (!location) continue

    // Skip if parties already exist for this partner
    const { data: existingParties } = await sb.from('parties').select('id').eq('partner_id', partner.id)
    if (existingParties && existingParties.length > 0) continue

    for (const scenario of SCENARIOS) {
      const verifIds = scenario.verificationCategory
        ? [verifByInternal[`global_${scenario.verificationCategory}`]].filter(Boolean)
        : []

      const { eventIds } = await createPartyWithEvents(sb, partner.id, location.id, scenario, verifIds)
      createdParties++
      createdEvents += eventIds.length
    }
  }

  return { createdParties, createdEvents }
}

async function purgeQueues(supabase: SupabaseClient): Promise<void> {
  for (const queue of ['q_global_events', 'q_notifications', 'q_vectors']) {
    try {
      await supabase.rpc('pgmq_purge', { queue_name: queue })
    } catch {
      // pgmq may not be available in all environments — ignore errors
    }
  }
}

async function seedUserActivity(sb: SupabaseClient): Promise<void> {
  // ── Step 0: Idempotency — clear previous activity data ──────────────
  // CASCADE will delete event_participants, verification_submissions too
  await sb.from('event_applications').delete().neq('id', '00000000-0000-0000-0000-000000000000')
  await sb.from('user_verifications').delete().neq('id', '00000000-0000-0000-0000-000000000000')

  // ── Step 1: Collect reference data ──────────────────────────────────
  const { data: users } = await sb.from('user_profiles')
    .select('id, username, gender, birth_date, is_verified')
    .not('username', 'like', 'partner_%')
  if (!users || users.length === 0) return

  const { data: events } = await sb.from('events')
    .select('id, party_id, status, max_participants, parties!inner(partner_id, required_verification_ids)')
  if (!events || events.length === 0) return

  const { data: allTickets } = await sb.from('tickets')
    .select('id, event_id, price, quantity')
  if (!allTickets || allTickets.length === 0) return

  const { data: verifications } = await sb.from('verifications')
    .select('id, partner_id, category, internal_name')
  if (!verifications) return

  // Helper: get tickets for an event
  const ticketsForEvent = (eventId: string) => allTickets.filter((t: any) => t.event_id === eventId)

  // ── Step 2: Seed user_verifications for verified users ───────────────
  const verifiedUsers = users.filter((u: any) => u.is_verified)
  const globalVerifs = verifications.filter((v: any) => v.partner_id === null)

  for (const user of verifiedUsers.slice(0, 20)) {
    for (const verif of globalVerifs) {
      await sb.from('user_verifications').upsert({
        user_id: user.id,
        verification_id: verif.id,
        data: { verified: true, source: 'seed' },
      }, { onConflict: 'user_id,verification_id', ignoreDuplicates: true })
    }
  }

  // ── Step 3: Pick events for activity seeding ─────────────────────────
  // Pick 3 events WITH verification + 3 events WITHOUT to cover all application statuses
  const allScheduled = events.filter((e: any) => e.status === 'scheduled')
  const withVerif = allScheduled.filter((e: any) => ((e as any).parties?.required_verification_ids ?? []).length > 0).slice(0, 3)
  const withoutVerif = allScheduled.filter((e: any) => ((e as any).parties?.required_verification_ids ?? []).length === 0).slice(0, 3)
  const scheduledEvents = [...withVerif, ...withoutVerif]
  if (scheduledEvents.length === 0) return
  if (scheduledEvents.length === 0) return

  // ── Step 4: Seed event_applications (ALL as 'pending' or 'pending_review' first) ──
  const applicationIds: { id: string; eventId: string; userId: string; ticketId: string; scenario: string }[] = []

  for (let ei = 0; ei < Math.min(scheduledEvents.length, 6); ei++) {
    const event = scheduledEvents[ei]
    const tickets = ticketsForEvent(event.id)
    if (tickets.length === 0) continue

    const ticket = tickets[0]
    const requiredVerifIds: string[] = (event as any).parties?.required_verification_ids ?? []
    const needsVerification = requiredVerifIds.length > 0

    // Pick users for this event (different users per event to avoid unique constraint)
    // Pick users for this event (5 per event to cover all scenarios)
    const eventUsers = users.slice(ei * 5, ei * 5 + 5)
    if (eventUsers.length === 0) continue

    for (let ui = 0; ui < eventUsers.length; ui++) {
      const user = eventUsers[ui]
      const scenario = needsVerification
        ? (ui === 0 ? 'pending_review_approved' : ui === 1 ? 'pending_review_rejected' : ui === 2 ? 'pending_review_needs_correction' : 'pending_review_pending')
        : (ui === 0 ? 'approved' : ui === 1 ? 'paid' : ui === 2 ? 'cancelled' : ui === 3 ? 'payment_failed' : 'pending')

      const { data: app, error: appErr } = await sb.from('event_applications').insert({
        event_id: event.id,
        ticket_id: ticket.id,
        user_id: user.id,
        status: needsVerification ? 'pending_review' : 'pending',
        message: `시드 데이터 신청 - ${scenario}`,
      }).select('id').single()

      if (appErr) {
        console.error(`Failed to create application for user ${user.id} event ${event.id}: ${appErr.message}`)
        continue
      }

      applicationIds.push({ id: app.id, eventId: event.id, userId: user.id, ticketId: ticket.id, scenario })
    }
  }

  // ── Step 5: Seed verification_submissions (for pending_review apps) ──
  const reviewApps = applicationIds.filter(a => a.scenario.startsWith('pending_review'))

  for (const app of reviewApps) {
    const event = scheduledEvents.find((e: any) => e.id === app.eventId)
    if (!event) continue
    const requiredVerifIds: string[] = (event as any).parties?.required_verification_ids ?? []
    if (requiredVerifIds.length === 0) continue

    const verifId = requiredVerifIds[0]
    const partnerId = (event as any).parties?.partner_id
    if (!partnerId) continue

    const { data: sub, error: subErr } = await sb.from('verification_submissions').insert({
      partner_id: partnerId,
      user_id: app.userId,
      verification_id: verifId,
      application_id: app.id,
      status: 'pending',
      snapshot_data: { submitted_at: new Date().toISOString(), data: { note: 'seed data' } },
    }).select('id').single()

    if (subErr) {
      console.error(`Failed to create verification_submission: ${subErr.message}`)
      continue
    }

    // Update submission to target status (triggers handle cascade)
    let targetStatus: string | null = null
    if (app.scenario === 'pending_review_approved') targetStatus = 'approved'
    else if (app.scenario === 'pending_review_rejected') targetStatus = 'rejected'
    else if (app.scenario === 'pending_review_needs_correction') targetStatus = 'needs_correction'

    if (targetStatus) {
      await sb.from('verification_submissions').update({
        status: targetStatus,
        admin_comment: targetStatus === 'rejected' ? '인증 서류 불충분' : targetStatus === 'needs_correction' ? '추가 서류 필요' : null,
        reviewed_at: new Date().toISOString(),
      }).eq('id', sub.id)
    }
  }

  // ── Step 6: Update non-verification event_applications to target statuses ──
  const directApps = applicationIds.filter(a => !a.scenario.startsWith('pending_review'))

  for (const app of directApps) {
    const ticket = allTickets.find((t: any) => t.id === app.ticketId)
    const ticketPrice = ticket?.price ?? 20000

    if (app.scenario === 'approved') {
      await sb.from('event_applications').update({ status: 'approved' }).eq('id', app.id)
    } else if (app.scenario === 'paid') {
      await sb.from('event_applications').update({ status: 'approved' }).eq('id', app.id)
      await sb.from('event_applications').update({
        status: 'paid',
        payment_id: `seed_pay_${app.id.slice(0, 8)}`,
        payment_amount: ticketPrice,
      }).eq('id', app.id)
    } else if (app.scenario === 'cancelled') {
      await sb.from('event_applications').update({ status: 'cancelled' }).eq('id', app.id)
    } else if (app.scenario === 'payment_failed') {
      await sb.from('event_applications').update({ status: 'approved' }).eq('id', app.id)
      await sb.from('event_applications').update({
        status: 'payment_failed',
        payment_id: null,
        payment_amount: null,
      }).eq('id', app.id)
    }
  }

  // ── Step 7: Update event_participants to checked_in / no_show ────────
  const { data: participants } = await sb.from('event_participants').select('id').limit(20)
  if (participants && participants.length > 0) {
    const checkinCount = Math.max(1, Math.floor(participants.length / 3))
    for (let i = 0; i < checkinCount; i++) {
      await sb.from('event_participants').update({ status: 'checked_in' }).eq('id', participants[i].id)
    }
    const noShowCount = Math.max(1, Math.floor(participants.length / 3))
    for (let i = checkinCount; i < checkinCount + noShowCount && i < participants.length; i++) {
      await sb.from('event_participants').update({ status: 'no_show' }).eq('id', participants[i].id)
    }
  }

  // ── Step 8: Update 1-2 events to completed/cancelled ─────────────────
  const { data: paidApps } = await sb.from('event_applications')
    .select('event_id')
    .eq('status', 'paid')
    .limit(1)

  if (paidApps && paidApps.length > 0) {
    await sb.from('events').update({ status: 'completed' }).eq('id', paidApps[0].event_id)
  }

  // Cancel a different event than the completed one
  if (scheduledEvents.length >= 2) {
    const completedEventId = paidApps?.[0]?.event_id
    const cancelEvent = scheduledEvents.find((e: any) => e.id !== completedEventId)
    if (cancelEvent) {
      await sb.from('events').update({ status: 'cancelled' }).eq('id', cancelEvent.id)
    }
  }

  // ── Step 9: Refund scenarios ──────────────────────────────────────────
  const { data: cancelledAppsList } = await sb.from('event_applications')
    .select('id')
    .eq('status', 'cancelled')
    .limit(4)

  if (cancelledAppsList && cancelledAppsList.length >= 1) {
    await sb.from('event_applications').update({ refund_status: 'requested' }).eq('id', cancelledAppsList[0].id)
    if (cancelledAppsList.length >= 2) {
      await sb.from('event_applications').update({
        refund_status: 'completed',
        refund_amount: 10000,
      }).eq('id', cancelledAppsList[1].id)
    }
  }
}

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

    // 1. 유저 560명 + 파트너 오너 (1 RPC, ~3초)
    // Partner owner personas (not part of generateAllPersonas)
    const partnerOwnerPersonas: UserPersona[] = [
      ...SEED_PARTNERS.map((pDef, idx) => ({
        email: pDef.ownerEmail,
        password: SEED_PASSWORD,
        metadata: {
          name: `${pDef.name} 대표`,
          username: pDef.ownerEmail.replace('@test.com', ''),
          gender: 'male' as const,
          birth_date: '1990-01-01',
          phone_number: `010-0000-${String(idx).padStart(4, '0')}`,
          is_verified: true,
        },
      })),
      ...HOT_PLACES.map((place, idx) => ({
        email: `partner_hotplace_${idx}@test.com`,
        password: SEED_PASSWORD,
        metadata: {
          name: `${place.name} 파트너`,
          username: `partner_hotplace_${idx}`,
          gender: 'male' as const,
          birth_date: '1988-01-01',
          phone_number: `010-0001-${String(idx).padStart(4, '0')}`,
          is_verified: true,
        },
      })),
    ]
    const allPersonas = [...generateAllPersonas(), ...partnerOwnerPersonas]
    const userResult = await supabase.rpc('dev_seed_bulk_users', {
      p_users: JSON.stringify(allPersonas.map(p => ({
        email: p.email,
        name: p.metadata.name,
        username: p.metadata.username,
        gender: p.metadata.gender,
        birth_date: p.metadata.birth_date,
        phone_number: p.metadata.phone_number,
        is_verified: p.metadata.is_verified,
        sim_region: null,
        sim_lat: null,
        sim_lng: null,
      }))),
      p_password: SEED_PASSWORD,
    })
    if (userResult.error) throw new Error(`dev_seed_bulk_users: ${userResult.error.message}`)
    console.log(`Users: ${userResult.data.created} created, ${userResult.data.updated} updated (${userResult.data.elapsed_ms}ms)`)

    // 2. 파트너 + 로케이션 + 인증 + 역할 (1 RPC, ~1초)
    const partnerResult = await supabase.rpc('dev_seed_bulk_partners', {
      p_partners: JSON.stringify(ALL_PARTNERS.map(p => ({
        name: p.name,
        introduction: p.introduction,
        biz_name: p.biz_name,
        biz_number: p.biz_number,
        contact_email: p.contact_email,
        owner_email: p.ownerEmail,
        location: p.location,
        local_verifications: p.localVerifications,
      }))),
      p_global_verifications: JSON.stringify(GLOBAL_VERIFICATIONS),
    })
    if (partnerResult.error) throw new Error(`dev_seed_bulk_partners: ${partnerResult.error.message}`)
    console.log(`Partners: ${partnerResult.data.partners_processed} (${partnerResult.data.elapsed_ms}ms)`)

    // 3. 파티 + 이벤트 (파트너별 시나리오 생성)
    const { createdParties, createdEvents } = await seedPartiesAndEvents(supabase)
    console.log(`Parties: ${createdParties}, Events: ${createdEvents}`)

    // 4. 이미지 (Storage API, ~10초 — RPC 불가)
    const imageUrls = await uploadSeedImages(supabase)
    await updatePartyImages(supabase, imageUrls)

    // 5. 유저 활동 (신청, 인증, 참가자)
    await seedUserActivity(supabase)

    // 6. pgmq 퍼지 (큐 블로트 방지)
    await purgeQueues(supabase)

    return new Response(
      JSON.stringify({
        users: userResult.data,
        partners_processed: partnerResult.data.partners_processed,
        created_parties: createdParties,
        created_events: createdEvents,
        uploaded_images: imageUrls.length,
        seeded_activity: true,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
