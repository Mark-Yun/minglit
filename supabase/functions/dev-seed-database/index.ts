import { createClient, SupabaseClient } from '@supabase/supabase-js'

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

  for (const filename of imageFiles) {
    try {
      const bytes = await Deno.readFile(`./assets/${filename}`)
      const path = `seed-images/${filename}`

      const { error } = await supabase.storage
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
         phone_number: '010-0000-0000',
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
     const ownerEmail = `partner_${place.region_2.replace(/구$/, '').toLowerCase()}@test.com`
     const ownerPersona: UserPersona = {
       email: ownerEmail,
       password: 'password1234!',
       metadata: {
         name: `${place.name} 파트너`,
         username: ownerEmail.replace('@test.com', ''),
         gender: 'male',
         birth_date: '1988-01-01',
         phone_number: '010-0000-0001',
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

    // Seed users
    const createdUsers = await seedUsers(supabase)

    // Seed 30s users
    const created30sUsers = await seed30sUsers(supabase)

     // Seed global verifications
     const globalVerifs = await seedGlobalVerifications(supabase)

     // Seed defined partners with their locations, verifications, parties, and events
     const definedPartnerStats = await seedDefinedPartners(supabase, globalVerifs)

     // Seed hot-place partners with all scenarios
     const hotPlaceStats = await seedHotPlacePartners(supabase, globalVerifs)

    // Upload seed images and update party image_urls
    const imageUrls = await uploadSeedImages(supabase)
    await updatePartyImages(supabase, imageUrls)

    // Purge pgmq queues to avoid queue bloat after seeding
    for (const queue of ['q_global_events', 'q_notifications', 'q_vectors']) {
      await supabase.rpc('pgmq_purge', { queue_name: queue }).catch(() => {
        // pgmq may not be available in all environments — ignore errors
      })
    }

     return new Response(
      JSON.stringify({
        created_users: createdUsers + SEED_PARTNERS.length + HOT_PLACES.length,
        created_30s_users: created30sUsers,
        created_partners: definedPartnerStats.createdPartners + hotPlaceStats.createdPartners,
        created_parties: definedPartnerStats.createdParties + hotPlaceStats.createdParties,
        created_events: definedPartnerStats.createdEvents + hotPlaceStats.createdEvents,
        uploaded_images: imageUrls.length,
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
