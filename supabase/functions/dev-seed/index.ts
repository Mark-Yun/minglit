import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { createServiceClient } from '../_shared/supabase_client.ts'
import { errorResponse, successResponse } from '../_shared/response_utils.ts'

function isProduction(): boolean {
  const env = Deno.env.get('ENVIRONMENT')
  return env !== 'local' && env !== 'development'
}

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

async function createAdminUser(
  supabase: SupabaseClient,
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

async function createPartner(
  sb: SupabaseClient,
  ownerId: string,
  partnerDef: { name: string; introduction: string; biz_name: string; biz_number: string; contact_email: string },
): Promise<string> {
  const { data, error } = await sb.from('partners').insert({
    name: partnerDef.name,
    introduction: partnerDef.introduction,
    biz_name: partnerDef.biz_name,
    biz_number: partnerDef.biz_number,
    contact_email: partnerDef.contact_email,
  }).select('id').single()

  if (error) throw new Error(`Failed to create partner "${partnerDef.name}": ${error.message}`)

  const { error: permError } = await sb.from('partner_member_permissions').insert({
    partner_id: data.id,
    user_id: ownerId,
    role: 'owner',
  })
  if (permError) throw new Error(`Failed to add owner permission: ${permError.message}`)

  return data.id
}

async function createLocation(
  sb: SupabaseClient,
  partnerId: string,
  loc: typeof HOT_PLACES[number],
): Promise<string> {
  const { data, error } = await sb.from('locations').insert({
    partner_id: partnerId,
    name: loc.name,
    address: loc.address,
    region_1: loc.region_1,
    region_2: loc.region_2,
    region_3: loc.region_3,
    geo_point: `POINT(${loc.lng} ${loc.lat})`,
  }).select('id').single()

  if (error) throw new Error(`Failed to create location "${loc.name}": ${error.message}`)
  return data.id
}

async function createVerification(
  sb: SupabaseClient,
  partnerId: string | null,
  verif: { category: string; internal_name: string; display_name: string; description: string; icon_key: string; form_schema: unknown[] },
): Promise<string> {
  const { data, error } = await sb.from('verifications').insert({
    partner_id: partnerId,
    category: verif.category,
    internal_name: verif.internal_name,
    display_name: verif.display_name,
    description: verif.description,
    icon_key: verif.icon_key,
    form_schema: verif.form_schema,
  }).select('id').single()

  if (error) throw new Error(`Failed to create verification "${verif.internal_name}": ${error.message}`)
  return data.id
}

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

async function ensureGlobalVerifications(sb: SupabaseClient): Promise<Record<string, string>> {
   const globals = [
     { category: 'career', internal_name: 'global_career', display_name: '직장인 인증', description: '재직증명서 기반 직장인 인증', icon_key: 'briefcase', form_schema: [{ type: 'image', label: '재직증명서' }] },
     { category: 'academic', internal_name: 'global_academic', display_name: '대학생 인증', description: '학생증 기반 대학생 인증', icon_key: 'school', form_schema: [{ type: 'image', label: '학생증' }] },
     { category: 'asset', internal_name: 'global_asset', display_name: '자산 인증', description: '자산 보유 인증', icon_key: 'diamond', form_schema: [{ type: 'text', label: '자산 정보' }] },
   ]

   const result: Record<string, string> = {}

   for (const g of globals) {
     const { data: existing } = await sb.from('verifications')
       .select('id')
       .is('partner_id', null)
       .eq('internal_name', g.internal_name)
       .maybeSingle()

     if (existing) {
       result[g.category] = existing.id
     } else {
       const id = await createVerification(sb, null, g)
       result[g.category] = id
     }
   }

   return result
 }

// ─── Domain Seeding Functions ───────────────────────────────────────

async function seedUsers(supabase: SupabaseClient): Promise<number> {
   const personas = generatePersonas()
   let createdUsers = 0

   for (const persona of personas) {
     try {
       await createAdminUser(supabase, persona)
       createdUsers++
     } catch (err) {
       console.error(`Failed to create ${persona.email}:`, err)
     }
   }

   return createdUsers
 }

async function seed30sUsers(supabase: SupabaseClient): Promise<number> {
  const personas = generate30sPersonas()
  let createdUsers = 0

  for (const persona of personas) {
    try {
      await createAdminUser(supabase, persona)
      createdUsers++
    } catch (err) {
      console.error(`Failed to create ${persona.email}:`, err)
    }
  }

  return createdUsers
}

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

  // Fix #456: batch update via Promise.all to avoid Edge Function timeout
  await Promise.all(parties.map((party: any, i: number) => {
    const shuffled = [
      imageUrls[i % imageUrls.length],
      imageUrls[(i + 1) % imageUrls.length],
      imageUrls[(i + 2) % imageUrls.length],
    ]
    return supabase.from('parties').update({ image_urls: shuffled }).eq('id', party.id)
  }))
}

async function seedGlobalVerifications(supabase: SupabaseClient): Promise<Record<string, string>> {
   return await ensureGlobalVerifications(supabase)
 }

async function seedDefinedPartners(
   supabase: SupabaseClient,
   globalVerifs: Record<string, string>,
 ): Promise<{ createdPartners: number; createdParties: number; createdEvents: number }> {
   let createdPartners = 0
   let createdParties = 0
   let createdEvents = 0

   for (const pDef of SEED_PARTNERS) {
     const ownerPersona: UserPersona = {
       email: pDef.ownerEmail,
       password: 'password1234!',
       metadata: {
         name: `${pDef.name} 대표`,
         username: pDef.ownerEmail.replace('@test.com', ''),
         gender: 'male',
         birth_date: '1990-01-01',
         phone_number: `010-0000-${String(SEED_PARTNERS.indexOf(pDef)).padStart(4, '0')}`,
         is_verified: true,
       },
     }

     let ownerId: string
     try {
       ownerId = await createAdminUser(supabase, ownerPersona)
     } catch (err) {
       console.error(`Failed to create partner owner ${pDef.ownerEmail}:`, err)
       continue
     }

     const partnerId = await createPartner(supabase, ownerId, pDef)
     createdPartners++

     const locationId = await createLocation(supabase, partnerId, pDef.location)

     const localVerifIds: Record<string, string> = {}
     for (const lv of pDef.localVerifications) {
       const vid = await createVerification(supabase, partnerId, lv)
       localVerifIds[lv.category] = vid
     }

     const scenarioIdx = SEED_PARTNERS.indexOf(pDef)
     const scenario = SCENARIOS[scenarioIdx % SCENARIOS.length]
     const verifIds = scenario.verificationCategory
       ? [localVerifIds[scenario.verificationCategory] ?? globalVerifs[scenario.verificationCategory]].filter(Boolean)
       : []

     const { eventIds } = await createPartyWithEvents(supabase, partnerId, locationId, scenario, verifIds)
     createdParties++
     createdEvents += eventIds.length
   }

   return { createdPartners, createdParties, createdEvents }
 }

async function seedHotPlacePartners(
   supabase: SupabaseClient,
   globalVerifs: Record<string, string>,
 ): Promise<{ createdPartners: number; createdParties: number; createdEvents: number }> {
   let createdPartners = 0
   let createdParties = 0
   let createdEvents = 0

   for (const place of HOT_PLACES) {
     const ownerEmail = `partner_hotplace_${HOT_PLACES.indexOf(place)}@test.com`
     const ownerPersona: UserPersona = {
       email: ownerEmail,
       password: 'password1234!',
       metadata: {
         name: `${place.name} 파트너`,
         username: ownerEmail.replace('@test.com', ''),
         gender: 'male',
         birth_date: '1988-01-01',
         phone_number: `010-0001-${String(HOT_PLACES.indexOf(place)).padStart(4, '0')}`,
         is_verified: true,
       },
     }

     let ownerId: string
     try {
       ownerId = await createAdminUser(supabase, ownerPersona)
     } catch (err) {
       console.error(`Failed to create hot-place partner owner ${ownerEmail}:`, err)
       continue
     }

     const partnerId = await createPartner(supabase, ownerId, {
       name: `${place.name} 소셜클럽`,
       introduction: `${place.name} 지역 대표 소셜 클럽`,
       biz_name: `${place.name}클럽`,
       biz_number: `000-00-${String(HOT_PLACES.indexOf(place)).padStart(5, '0')}`,
       contact_email: ownerEmail,
     })
     createdPartners++

     const locationId = await createLocation(supabase, partnerId, place)

     for (const scenario of SCENARIOS) {
       const verifIds = scenario.verificationCategory
         ? [globalVerifs[scenario.verificationCategory]].filter(Boolean)
         : []

       const { eventIds } = await createPartyWithEvents(supabase, partnerId, locationId, scenario, verifIds)
       createdParties++
       createdEvents += eventIds.length
     }
   }

   return { createdPartners, createdParties, createdEvents }
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

  // Fix #456: batch upsert to avoid Edge Function timeout
  const uvRows: { user_id: string; verification_id: string; data: { verified: boolean; source: string } }[] = []
  for (const user of verifiedUsers.slice(0, 20)) {
    for (const verif of globalVerifs) {
      uvRows.push({
        user_id: user.id,
        verification_id: verif.id,
        data: { verified: true, source: 'seed' },
      })
    }
  }
  if (uvRows.length > 0) {
    await sb.from('user_verifications').upsert(uvRows, { onConflict: 'user_id,verification_id', ignoreDuplicates: true }).throwOnError()
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
        ? (ui === 0 ? 'pending_review_approved' : ui === 1 ? 'pending_review_rejected' : 'pending_review_pending')
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
      snapshot_data: [{ submitted_at: new Date().toISOString(), data: { note: 'seed data' }, result: null, reviewed_by: null, reviewed_at: null, comments: [] }],
    }).select('id').single()

    if (subErr) {
      console.error(`Failed to create verification_submission: ${subErr.message}`)
      continue
    }

    // Update submission to target status (triggers handle cascade)
    let targetStatus: string | null = null
    if (app.scenario === 'pending_review_approved') targetStatus = 'approved'
    else if (app.scenario === 'pending_review_rejected') targetStatus = 'rejected'

    if (targetStatus) {
      await sb.from('verification_submissions').update({
        status: targetStatus,
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
    const noShowCount = Math.max(1, Math.floor(participants.length / 3))

    // Fix #456: batch upsert to avoid Edge Function timeout
    const checkedInIds = participants.slice(0, checkinCount).map((p: any) => p.id)
    if (checkedInIds.length > 0) {
      await sb.from('event_participants').update({ status: 'checked_in' }).in('id', checkedInIds).throwOnError()
    }

    const noShowIds = participants.slice(checkinCount, checkinCount + noShowCount).map((p: any) => p.id)
    if (noShowIds.length > 0) {
      await sb.from('event_participants').update({ status: 'no_show' }).in('id', noShowIds).throwOnError()
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

  // ── Step 10: Expand partner_verified_users pool ────────────────────────
  const { data: allUsers } = await sb.from('user_profiles')
    .select('id')
    .not('username', 'like', 'partner_%')
    .limit(30)

  const { data: allPartners } = await sb.from('partners').select('id')
  const { data: allVerifications } = await sb.from('verifications').select('id, partner_id')

  if (allUsers && allPartners && allVerifications) {
    // Fix #456: batch upsert to avoid Edge Function timeout
    const pvuRows: { partner_id: string; user_id: string; verification_id: string; verified_at: string }[] = []
    const now = new Date().toISOString()
    for (const user of allUsers) {
      for (const partner of allPartners) {
        const partnerVerifs = allVerifications.filter((v: any) =>
          v.partner_id === partner.id || v.partner_id === null
        )
        for (const verif of partnerVerifs) {
          pvuRows.push({
            partner_id: partner.id,
            user_id: user.id,
            verification_id: verif.id,
            verified_at: now,
          })
        }
      }
    }
    if (pvuRows.length > 0) {
      // Note: submission_id is NOT NULL — direct upsert may fail.
      // This step is best-effort; partner_verified_users are normally
      // populated via the verification_submissions approval trigger.
      try {
        await sb.from('partner_verified_users').upsert(pvuRows, { onConflict: 'partner_id,user_id,verification_id' }).throwOnError()
      } catch (err) {
        console.error('partner_verified_users batch upsert failed (expected if submission_id NOT NULL):', err)
      }
    }
  }

  // ── Step 11: Seed match_rules for scheduled events ─────────────────────
  const { data: eventsForRules } = await sb.from('events')
    .select('id, entry_groups!inner(id)')
    .eq('status', 'scheduled')

  if (eventsForRules) {
    // Fix #456: batch upsert to avoid Edge Function timeout
    const matchRuleRows: { event_id: string; source_group_id: string; target_group_id: string }[] = []
    for (const event of eventsForRules) {
      const groups = (event as any).entry_groups ?? []
      if (groups.length >= 2) {
        matchRuleRows.push(
          { event_id: event.id, source_group_id: groups[0].id, target_group_id: groups[1].id },
          { event_id: event.id, source_group_id: groups[1].id, target_group_id: groups[0].id },
        )
      }
    }
    if (matchRuleRows.length > 0) {
      await sb.from('match_rules').upsert(matchRuleRows, { onConflict: 'event_id,source_group_id,target_group_id', ignoreDuplicates: true }).throwOnError()
    }
  }
}

// Fix #489: phase-split으로 150s wall clock 제한 우회 — phase=1/2/3 개별 호출 또는 미지정 시 전체 실행
Deno.serve(async (req) => {
  // Handle CORS preflight before any auth/env checks
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS' } })
  }

  if (isProduction()) {
    return errorResponse('Dev-only function. Blocked in production.', 403)
  }

  try {
    const supabase = createServiceClient()
    const url = new URL(req.url)
    const phase = url.searchParams.get('phase')

    // Reject unknown phase values to prevent accidental full runs
    if (phase !== null && !['1', '2', '3'].includes(phase)) {
      return errorResponse(`Invalid phase: ${phase}. Use 1, 2, or 3.`, 400)
    }

    // Phase 1: Users + Global verifications
    let createdUsers = 0
    let created30sUsers = 0
    let globalVerifsCount = 0
    if (!phase || phase === '1') {
      createdUsers = await seedUsers(supabase)
      created30sUsers = await seed30sUsers(supabase)
      const globalVerifs = await seedGlobalVerifications(supabase)
      globalVerifsCount = Object.keys(globalVerifs).length

      if (phase === '1') {
        return successResponse({ phase: 1, created_users: createdUsers, created_30s_users: created30sUsers, global_verifications: globalVerifsCount })
      }
    }

    // Phase 2: Partners + Images upload
    // ensureGlobalVerifications fetches existing records if already created in Phase 1
    let totalPartners = 0
    let totalParties = 0
    let totalEvents = 0
    let uploadedImages = 0
    if (!phase || phase === '2') {
      const globalVerifs = await ensureGlobalVerifications(supabase)
      const definedPartnerStats = await seedDefinedPartners(supabase, globalVerifs)
      const hotPlaceStats = await seedHotPlacePartners(supabase, globalVerifs)
      const imageUrls = await uploadSeedImages(supabase)
      totalPartners = definedPartnerStats.createdPartners + hotPlaceStats.createdPartners
      totalParties = definedPartnerStats.createdParties + hotPlaceStats.createdParties
      totalEvents = definedPartnerStats.createdEvents + hotPlaceStats.createdEvents
      uploadedImages = imageUrls.length

      if (phase === '2') {
        return successResponse({ phase: 2, created_partners: totalPartners, created_parties: totalParties, created_events: totalEvents, uploaded_images: uploadedImages })
      }
    }

    // Phase 3: Party images + User activity + Queue purge
    // uploadSeedImages is idempotent — returns existing URLs without re-uploading
    if (!phase || phase === '3') {
      const imageUrls = await uploadSeedImages(supabase)
      await updatePartyImages(supabase, imageUrls)
      await seedUserActivity(supabase)

      for (const queue of ['q_global_events', 'q_notifications', 'q_vectors']) {
        try {
          await supabase.rpc('pgmq_purge', { queue_name: queue })
        } catch {
          // pgmq may not be available in all environments — ignore errors
        }
      }

      if (phase === '3') {
        return successResponse({ phase: 3, seeded_activity: true })
      }
    }

    // Full run (no phase param) — runs all phases sequentially and returns combined stats.
    // Note: uploadSeedImages is called in both Phase 2 and Phase 3, but it is idempotent
    // (skips already-uploaded files), so double-calling is safe and intentional.
    // For environments with strict 150s wall clock limits, call phase=1/2/3 individually.
    // created_users includes partner owner accounts (SEED_PARTNERS + HOT_PLACES)
    return successResponse({
      full_run: true,
      created_users: createdUsers + SEED_PARTNERS.length + HOT_PLACES.length,
      created_30s_users: created30sUsers,
      created_partners: totalPartners,
      created_parties: totalParties,
      created_events: totalEvents,
    })
  } catch (err) {
    return errorResponse((err as Error).message, 500)
  }
})
