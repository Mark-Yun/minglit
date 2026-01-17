import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// **Database Seeder**
///
/// Handles programmatic data seeding using JSON assets for local development.
/// This package is designed to be standalone and not depend on minglit_kit.
class DatabaseSeeder {
  DatabaseSeeder(this._adminClient);

  final SupabaseClient _adminClient;

  /// Runs the full seeding process.
  Future<void> seed() async {
    _Log.i('🌱 [Seeder] Starting Fresh Seeding from JSON...');

    try {
      // 1. Load Seed Data from JSON
      // Note: When loading assets from a package, use 'packages/<package_name>/<path>'
      final jsonStr = await rootBundle.loadString(
        'packages/test_data_seeder/assets/seed_data.json',
      );
      final seedData = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 2. Fetch Global Verifications (created by seed.sql)
      final globalVerifIds = await _getGlobalVerificationIds();
      _Log.i('✅ Global Verifications Found: ${globalVerifIds.length} items');

      // 3. Create Normal Users (Personas)
      await _seedPersonas();

      // 4. Create Partners & Diverse Content from JSON
      await _processSeedData(seedData, globalVerifIds);

      _Log.i('✅ [Seeder] Seeding Completed!');
    } on Object catch (e, st) {
      _Log.e('🔥 [Seeder] Seeding Failed', e, st);
      rethrow;
    }
  }

  Future<List<String>> _getGlobalVerificationIds() async {
    final result = await _adminClient
        .from('verifications')
        .select('id')
        .filter('partner_id', 'is', null);

    return (result as List)
        .map((dynamic e) => (e as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  /// Generates 124+ detailed user personas for testing diverse scenarios.
  ///
  /// Scenarios:
  /// - Ages: 20-50 (31 ages)
  /// - Gender: Male (2), Female (2) per age
  /// - Status: Verified vs Unverified
  Future<void> _seedPersonas() async {
    _Log.i('👥 Step 1: Seeding 124+ Persona Users...');

    final currentYear = DateTime.now().year;

    // 1. Standard Personas: Age 20 ~ 50 (31 years)
    for (var age = 20; age <= 50; age++) {
      final birthYear = currentYear - age + 1; // Korean age roughly
      final birthDate = '$birthYear-01-01';

      // 4 Personas per age
      final personas = [
        {'gender': 'male', 'verified': true, 'suffix': '인증O'},
        {'gender': 'male', 'verified': false, 'suffix': '인증X'},
        {'gender': 'female', 'verified': true, 'suffix': '인증O'},
        {'gender': 'female', 'verified': false, 'suffix': '인증X'},
      ];

      for (final p in personas) {
        final gender = p['gender'] as String;
        final verified = p['verified'] as bool;
        final suffix = p['suffix'] as String;
        final genderKr = gender == 'male' ? '남' : '여';
        final genderShort = gender == 'male' ? 'm' : 'f';
        final verifShort = verified ? 'ok' : 'no';

        final name = '${age}${genderKr}_$suffix';
        final username = 'user_${age}_${genderShort}_$verifShort';
        final email = '$username@test.com';

        // Unique phone number logic:
        // Middle: 1000 + age (e.g., 1020)
        // Last:
        //  - Verified (1) / Unverified (0)
        //  - Male (1) / Female (2)
        //  - 00 (padding)
        final last4 =
            '${verified ? "1" : "0"}${gender == "male" ? "1" : "2"}00';

        final metadata = <String, dynamic>{
          'name': name,
          'username': username,
          'gender': gender,
          'birth_date': birthDate,
          'phone_number': '010-${1000 + age}-$last4',
          'is_verified': verified, // Custom flag for easy check
        };

        await _createAdminUser(
          email: email,
          password: 'password1234!',
          metadata: metadata,
        );
      }
    }

    // 2. Edge Case Personas
    // No profile image, no bio, etc.
    final edgeCases = [
      {
        'name': '40남_정보누락',
        'username': 'user_40_m_incomplete',
        'gender': 'male',
        'age': 40,
        'verified': false,
      },
      {
        'name': '25여_프로필없음',
        'username': 'user_25_f_noprofile',
        'gender': 'female',
        'age': 25,
        'verified': true,
      },
    ];

    for (final ec in edgeCases) {
      final age = ec['age'] as int;
      final birthYear = currentYear - age + 1;
      final metadata = <String, dynamic>{
        'name': ec['name'],
        'username': ec['username'],
        'gender': ec['gender'],
        'birth_date': '$birthYear-01-01',
        'phone_number': '010-9999-${age + 1000}',
      };

      await _createAdminUser(
        email: '${ec['username']}@test.com',
        password: 'password1234!',
        metadata: metadata,
      );
    }
  }

  Future<void> _processSeedData(
    Map<String, dynamic> seedData,
    List<String> globalVerifIds,
  ) async {
    final partners = seedData['partners'] as List<dynamic>;
    // final genericCount = seedData['generic_partners_count'] as int? ?? 0;

    _Log.i('🏢 Step 2: Processing ${partners.length} defined partners...');

    // 1. Process Defined Partners (JSON)
    for (final dynamic p in partners) {
      // ... (Existing logic for fixed JSON data, maybe refactor to reuse _createPartnerAndContent)
      // For simplicity, keeping existing logic for JSON data but updating ticket table
      final pData = p as Map<String, dynamic>;
      final index = pData['index'] as int;
      final partnerName = pData['name'] as String;
      final email = pData['email'] as String;

      final ownerId = await _createAdminUser(
        email: email,
        password: 'password1234!', // Secure password
        metadata: {
          'name': 'Owner $index ($partnerName)',
          'username': 'owner_$index',
          'gender': 'male',
        },
      );

      final partnerId = await _createPartner(
        ownerId,
        partnerName,
        pData['introduction'] ?? 'Premium Store',
        pData['biz_name'],
        pData['biz_number'],
        email,
      );

      // Location
      final locationId = await _createLocation(
        partnerId,
        '$partnerName Main Branch',
        'Seoul Gangnam-gu Gangnam-daero ${396 + index}',
        37.4979 + (index * 0.001),
        127.0276 + (index * 0.001),
      );

      // Verifications (Local)
      final localVerifIds = <String>[];
      final verifs = pData['verifications'] as List<dynamic>? ?? [];
      if (verifs.isNotEmpty) {
        final localVerifRes = await _adminClient
            .from('verifications')
            .insert(
              verifs.map((dynamic v) {
                final vMap = v as Map<String, dynamic>;
                return {...vMap, 'partner_id': partnerId};
              }).toList(),
            )
            .select('id');
        localVerifIds.addAll(
          (localVerifRes as List).map(
            (dynamic e) => (e as Map<String, dynamic>)['id'] as String,
          ),
        );
      }

      // Parties
      final parties = pData['parties'] as List<dynamic>? ?? [];
      for (final dynamic pEntry in parties) {
        final pMap = pEntry as Map<String, dynamic>;
        // Use rich description even for JSON-defined parties
        pMap['description'] = _generateRichDescription(
          pMap['title'] as String,
          pMap['description'] as String,
        );

        await _createPartyAndEvents(
          partnerId,
          locationId,
          pMap,
          globalVerifIds,
          localVerifIds,
        );
      }
    }

    // 2. Generate Random Partners & Content based on Hot Places
    _Log.i('🏢 Step 3: Generating Random Partners for Hot Places...');
    await _seedScenarioParties(globalVerifIds);
  }

  // --- Helper Methods ---

  final _hotPlaces = [
    {'name': '서울 강남', 'lat': 37.4979, 'lng': 127.0276},
    {'name': '서울 홍대', 'lat': 37.5575, 'lng': 126.9245},
    {'name': '서울 성수', 'lat': 37.5445, 'lng': 127.0559},
    {'name': '서울 이태원', 'lat': 37.5342, 'lng': 126.9946},
    {'name': '부산 서면', 'lat': 35.1578, 'lng': 129.0600},
    {'name': '부산 해운대', 'lat': 35.1587, 'lng': 129.1603},
    {'name': '대구 동성로', 'lat': 35.8714, 'lng': 128.5947},
    {'name': '대전 둔산동', 'lat': 36.3544, 'lng': 127.3776},
    {'name': '광주 충장로', 'lat': 35.1475, 'lng': 126.9166},
  ];

  Future<void> _seedScenarioParties(List<String> globalVerifIds) async {
    int partnerCounter = 100; // Start from 100 to avoid conflict with JSON

    // Find indices for verifications
    // Assuming the order from seed.sql insert or using known IDs would be safer.
    // For now, let's rely on IDs if possible, or assume typical order if fetching all.
    // Let's find index by checking against known IDs from seed.sql if available,
    // OR we can just fetch them by name in _getGlobalVerificationIds.
    // Given current helper just returns list, let's map them manually based on what we know.
    // But since we don't have the map, let's do a best effort or fetch map.
    // To be safe, let's just use the IDs directly in the scenarios and update helper later if needed.

    // Hardcoded IDs from seed.sql (minus identity)
    const careerId = '00000000-0000-0000-0000-000000000002';
    const academicId = '00000000-0000-0000-0000-000000000003';
    const assetId = '00000000-0000-0000-0000-000000000004';

    final careerIdx = globalVerifIds.indexOf(careerId);
    final academicIdx = globalVerifIds.indexOf(academicId);
    final assetIdx = globalVerifIds.indexOf(assetId);

    // 5 Scenarios
    final scenarios = [
      {
        'label': 'Scenario A (대학생)',
        'type': 'univ',
        'titles': ['설레는 캠퍼스 미팅', '대학생 개강 파티', '시험 끝! 종강 파티'],
        'desc_header': '풋풋한 대학생들의 설레는 만남.',
        'groups': [
          {
            'label': '대학생(남)',
            'gender': 'male',
            'birth_year_range': {'min': 2001, 'max': 2006}, // 20~25
            'use_global_ids': academicIdx != -1 ? [academicIdx] : [],
          },
          {
            'label': '대학생(여)',
            'gender': 'female',
            'birth_year_range': {'min': 2001, 'max': 2006},
            'use_global_ids': academicIdx != -1 ? [academicIdx] : [],
          },
        ],
      },
      {
        'label': 'Scenario B (직장인)',
        'type': 'office',
        'titles': ['직장인 퇴근 후 와인', '판교/강남 IT 네트워킹', '비슷한 결의 직장인 만남'],
        'desc_header': '열심히 일한 당신, 오늘 밤은 즐기세요.',
        'groups': [
          {
            'label': '직장인(남)',
            'gender': 'male',
            'birth_year_range': {'min': 1987, 'max': 1998}, // 28~39
            'use_global_ids': careerIdx != -1 ? [careerIdx] : [],
          },
          {
            'label': '직장인(여)',
            'gender': 'female',
            'birth_year_range': {'min': 1987, 'max': 1998},
            'use_global_ids': careerIdx != -1 ? [careerIdx] : [],
          },
        ],
      },
      {
        'label': 'Scenario C (노블레스)',
        'type': 'noble',
        'titles': ['프리미엄 프라이빗 파티', '성공한 사람들의 모임', '노블레스 라운지'],
        'desc_header': '검증된 분들을 위한 프라이빗한 시간.',
        'groups': [
          {
            'label': '노블레스(남)',
            'gender': 'male',
            'birth_year_range': null, // All ages
            'use_global_ids': assetIdx != -1 ? [assetIdx] : [],
          },
          {
            'label': '노블레스(여)',
            'gender': 'female',
            'birth_year_range': null,
            'use_global_ids': assetIdx != -1 ? [assetIdx] : [],
          },
        ],
      },
      {
        'label': 'Scenario D (동네 친구)',
        'type': 'local',
        'titles': ['동네 친구 만들기', '편맥 한잔 하실 분', '산책 메이트 구함'],
        'desc_header': '부담 없이 동네에서 만나요.',
        'groups': [
          {
            'label': '누구나 환영',
            'gender': null,
            'birth_year_range': {'min': 1980, 'max': 2006}, // Adult
            'use_global_ids': [], // No extra verification needed
          },
        ],
      },
      {
        'label': 'Scenario E (복합 조건)',
        'type': 'complex',
        'titles': ['능력남 & 매력녀 매칭', '전문직 남성 & 20대 여성', '특별한 당신을 위해'],
        'desc_header': '특별한 조건의 매칭을 경험해보세요.',
        'groups': [
          {
            'label': '전문직 남성',
            'gender': 'male',
            'birth_year_range': {'min': 1987, 'max': 1996}, // 30s
            'use_global_ids': careerIdx != -1 ? [careerIdx] : [],
          },
          {
            'label': '매력적인 20대 여성',
            'gender': 'female',
            'birth_year_range': {'min': 1997, 'max': 2006}, // 20s
            'use_global_ids': [], // No extra verification
          },
        ],
      },
    ];

    for (final place in _hotPlaces) {
      final placeName = place['name'] as String;
      final lat = place['lat'] as double;
      final lng = place['lng'] as double;

      // Create 1 Partner per Hot Place (Simplified from 3)
      partnerCounter++;
      final partnerName = '$placeName 핫플 파트너';
      final email = 'owner$partnerCounter@test.com';

      final ownerId = await _createAdminUser(
        email: email,
        password: 'password1234!',
        metadata: {
          'name': '사장님 $partnerCounter ($placeName)',
          'username': 'owner_$partnerCounter',
          'gender': 'male',
          'birth_date': '1990-01-01',
          'phone_number': '010-9999-$partnerCounter',
          'is_verified': true,
        },
      );

      final partnerId = await _createPartner(
        ownerId,
        partnerName,
        '$placeName에서 가장 핫한 라운지 바',
        'Minglit Corp $partnerCounter',
        '123-45-$partnerCounter',
        email,
      );

      final locationId = await _createLocation(
        partnerId,
        '$partnerName 본점',
        '$placeName 번화가 1길',
        lat,
        lng,
      );

      // Create 5 Parties (One for each scenario)
      for (final scenario in scenarios) {
        final titles = scenario['titles'] as List<String>;
        final title = '[$placeName] ${titles[partnerCounter % titles.length]}';
        final groups = scenario['groups'] as List<Map<String, dynamic>>;

        final entryGroups = <Map<String, dynamic>>[];
        final tickets = <Map<String, dynamic>>[];

        for (var i = 0; i < groups.length; i++) {
          final g = groups[i];
          entryGroups.add({
            'label': g['label'],
            'gender': g['gender'],
            'birth_year_range': g['birth_year_range'],
            'use_global_ids': g['use_global_ids'],
          });

          tickets.add({
            'name': '${g['label']} 입장권',
            'price': 20000 + (i * 5000), // Varies slightly
            'quantity': 10,
            'group_index': i,
          });
        }

        final partyData = {
          'title': title,
          'description': _generateRichDescription(
            title,
            '${scenario['desc_header']}\n[${scenario['label']}] 테마 파티입니다.',
          ),
          'entry_groups': entryGroups,
          'tickets': tickets,
        };

        await _createPartyAndEvents(
          partnerId,
          locationId,
          partyData,
          globalVerifIds,
          [],
        );
      }
    }
  }

  Map<String, dynamic> _generateRichDescription(String title, String summary) {
    return {
      "ops": [
        {
          "insert": "✨ $title\n",
          "attributes": {"header": 1, "bold": true},
        },
        {"insert": "\n"},
        {
          "insert": "📍 파티 소개\n",
          "attributes": {"header": 2},
        },
        {"insert": "$summary\n\n"},
        {
          "insert": "🕒 타임테이블\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "19:00 - 입장 및 웰컴 드링크\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "19:30 - 아이스브레이킹 게임 (어색함 타파!)\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "20:30 - 1:1 대화 로테이션 및 네트워킹\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "22:00 - 자유 대화 및 공식 행사 종료\n",
          "attributes": {"list": "bullet"},
        },
        {"insert": "\n"},
        {
          "insert": "✅ 제공 내역\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "레드/화이트/스파클링 와인 무제한\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "프리미엄 핑거 푸드 케이터링\n",
          "attributes": {"list": "bullet"},
        },
        {
          "insert": "매칭 확률을 높여주는 Minglit 가이드북\n",
          "attributes": {"list": "bullet"},
        },
        {"insert": "\n"},
        {
          "insert": "📢 안내 사항\n",
          "attributes": {"header": 2},
        },
        {
          "insert": "신분증 지참 필수입니다. (PASS 인증 확인)\n",
          "attributes": {"bold": true},
        },
        {"insert": "과도한 음주는 삼가주세요.\n"},
      ],
    };
  }

  Future<String> _createPartner(
    String ownerId,
    String name,
    String intro,
    String bizName,
    String bizNumber,
    String email,
  ) async {
    final partnerRes = await _adminClient
        .from('partners')
        .insert({
          'name': name,
          'introduction': intro,
          'biz_name': bizName,
          'biz_number': bizNumber,
          'contact_email': email,
        })
        .select('id')
        .single();
    final partnerId = partnerRes['id'] as String;

    await _adminClient.from('partner_member_permissions').insert({
      'partner_id': partnerId,
      'user_id': ownerId,
      'role': 'owner',
    });

    return partnerId;
  }

  Future<String> _createLocation(
    String partnerId,
    String name,
    String address,
    double lat,
    double lng,
  ) async {
    final locationRes = await _adminClient
        .from('locations')
        .insert({
          'partner_id': partnerId,
          'name': name,
          'address': address,
          'geo_point': 'POINT($lng $lat)',
        })
        .select('id')
        .single();
    return locationRes['id'] as String;
  }

  Future<void> _createPartyAndEvents(
    String partnerId,
    String locationId,
    Map<String, dynamic> partyData,
    List<String> globalVerifIds,
    List<String> localVerifIds,
  ) async {
    final partyId = const Uuid().v4();

    // Map Entry Groups & Tickets from input data
    final entryGroupsList = partyData['entry_groups'] as List<dynamic>;
    final ticketsList = partyData['tickets'] as List<dynamic>;

    final allVerifIds = entryGroupsList
        .expand((e) => (e as Map)['use_global_ids'] as List? ?? [])
        .map((e) => globalVerifIds[e as int]) // Map index to real ID
        .toSet()
        .toList();

    await _adminClient.from('parties').insert({
      'id': partyId,
      'partner_id': partnerId,
      'location_id': locationId,
      'title': partyData['title'],
      'description': partyData['description'],
      'min_confirmed_count': 5,
      'max_participants': 20,
      'required_verification_ids': allVerifIds,
    });

    // --- Template Creation (Skipping logic detailed check for brevity, assuming standard flow) ---
    // 1. Create Entry Group Templates
    final entryGroupTemplatesRes = await _adminClient
        .from('entry_group_templates')
        .insert(
          entryGroupsList.map((dynamic g) {
            final gMap = g as Map<String, dynamic>;
            final reqIds = (gMap['use_global_ids'] as List? ?? [])
                .map((i) => globalVerifIds[i as int])
                .toList();
            return {
              'party_id': partyId,
              'label': gMap['label'],
              'gender': gMap['gender'],
              'birth_year_min': gMap['birth_year_range']?['min'],
              'birth_year_max': gMap['birth_year_range']?['max'],
              'required_verification_ids': reqIds,
            };
          }).toList(),
        )
        .select('id');
    final templateIds = (entryGroupTemplatesRes as List)
        .map((e) => e['id'] as String)
        .toList();

    // 2. Create Ticket Templates
    await _adminClient
        .from('ticket_templates')
        .insert(
          ticketsList.map((dynamic t) {
            final tMap = t as Map<String, dynamic>;
            final groupIdx = tMap['group_index'] as int;
            return {
              'party_id': partyId,
              'name': tMap['name'],
              'price': tMap['price'],
              'quantity': tMap['quantity'],
              'target_entry_group_ids': [templateIds[groupIdx]],
            };
          }).toList(),
        );

    // --- Instance Creation (Events) ---
    final now = DateTime.now();
    final eventDates = [
      now.add(const Duration(hours: 3)),
      now.add(const Duration(days: 7)),
    ];

    for (final date in eventDates) {
      final eventId = const Uuid().v4();
      await _adminClient.from('events').insert({
        'id': eventId,
        'party_id': partyId,
        'location_id': locationId,
        'title': null,
        'start_time': date.toIso8601String(),
        'end_time': date.add(const Duration(hours: 4)).toIso8601String(),
        'max_participants': 30,
        'status': 'scheduled',
      });

      // 1. Create Event Entry Groups
      final eventGroupsRes = await _adminClient
          .from('entry_groups')
          .insert(
            entryGroupsList.map((dynamic g) {
              final gMap = g as Map<String, dynamic>;
              final reqIds = (gMap['use_global_ids'] as List? ?? [])
                  .map((i) => globalVerifIds[i as int])
                  .toList();
              return {
                'event_id': eventId,
                'label': gMap['label'],
                'gender': gMap['gender'],
                'birth_year_min': gMap['birth_year_range']?['min'],
                'birth_year_max': gMap['birth_year_range']?['max'],
                'required_verification_ids': reqIds,
              };
            }).toList(),
          )
          .select('id');
      final eventGroupIds = (eventGroupsRes as List)
          .map((e) => e['id'] as String)
          .toList();

      // 2. Create Event Tickets
      await _adminClient
          .from('tickets')
          .insert(
            ticketsList.map((dynamic t) {
              final tMap = t as Map<String, dynamic>;
              final groupIdx = tMap['group_index'] as int;
              return {
                'event_id': eventId,
                'name': tMap['name'],
                'price': tMap['price'],
                'quantity': tMap['quantity'],
                'target_entry_group_ids': [eventGroupIds[groupIdx]],
                'status': 'on_sale',
              };
            }).toList(),
          );
    }
  }

  Future<String> _createAdminUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final res = await _adminClient.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
          userMetadata: metadata,
        ),
      );
      final user = res.user;
      if (user == null) {
        throw Exception('User creation failed');
      }
      return user.id;
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.code == 'email_exists') {
        // Since listUsers might be slow or paginated, we try to find it.
        // For efficiency in seed, we might just skip or delete.
        // The original code tried to delete and recreate.
        final usersRes = await _adminClient.auth.admin.listUsers(perPage: 1000);
        try {
          final existing = usersRes.firstWhere((u) => u.email == email);
          await _adminClient.auth.admin.deleteUser(existing.id);
        } on Object catch (_) {
          // Ignore if not found or delete fails
        }
        // Retry create
        return _createAdminUser(
          email: email,
          password: password,
          metadata: metadata,
        );
      }
      rethrow;
    }
  }
}

class _Log {
  static void i(String message) {
    // print(message); // Simple print for CLI output
    dev.log(message, name: 'Seeder');
    print(message); // Also print to stdout for CI visibility
  }

  static void e(String message, Object error, StackTrace? stackTrace) {
    // print('$message\n$error\n$stackTrace');
    dev.log(message, name: 'Seeder', error: error, stackTrace: stackTrace);
    print('$message\n$error\n$stackTrace');
  }
}
