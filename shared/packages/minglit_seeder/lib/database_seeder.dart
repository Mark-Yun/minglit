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
        'packages/minglit_seeder/assets/seed_data.json',
      );
      final seedData = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 2. Fetch Global Verifications (created by seed.sql)
      final globalVerifIds = await _getGlobalVerificationIds();
      _Log.i('✅ Global Verifications Found: ${globalVerifIds.length} items');

      // 3. Create Normal Users
      await _seedUsers();

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

  Future<void> _seedUsers() async {
    _Log.i('👥 Step 1: Seeding 100 Normal Users...');
    for (var i = 1; i <= 100; i++) {
      final metadata = <String, dynamic>{
        'name': 'User $i',
        'username': 'user_$i',
        'gender': i.isOdd ? 'male' : 'female',
        'phone_number': '010-${1000 + i}-${2000 + i}',
      };

      await _createAdminUser(
        email: 'user$i@test.com',
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
    await _generateRandomContent(globalVerifIds);
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

  Future<void> _generateRandomContent(List<String> globalVerifIds) async {
    int partnerCounter = 100; // Start from 100 to avoid conflict with JSON

    // 4 Scenarios
    final scenarios = [
      {
        'type': '20s',
        'titles': ['두근두근 대학생 미팅', '20대 풋풋한 만남', '설레는 봄, 벚꽃 미팅'],
        'desc_header': '20대만의 에너지가 넘치는 파티!',
        'min_year': 1997, // 29세 (2026기준)
        'max_year': 2006, // 20세
        'split_gender': true,
      },
      {
        'type': '30s',
        'titles': ['30대 직장인 와인 파티', '퇴근 후 힐링 네트워킹', '진지한 만남, 가벼운 대화'],
        'desc_header': '비슷한 라이프스타일의 30대를 위한 공간.',
        'min_year': 1988, // 38세
        'max_year': 1998, // 28세
        'split_gender': true,
      },
      {
        'type': '40s',
        'titles': ['다시 사랑할 수 있을까', '40대 돌싱&골드미스/미스터', '편안한 대화가 있는 밤'],
        'desc_header': '인생의 경험을 나누며 서로에게 스며드는 시간.',
        'min_year': 1977, // 49세
        'max_year': 1991, // 35세 (여성은 조금 더 넓게 잡는 등 변주 가능하지만 일단 통일)
        'split_gender': true,
      },
      {
        'type': 'All',
        'titles': ['동네 친구 만들기', '누구나 환영! 맥주 파티', '개발자&기획자 네트워킹'],
        'desc_header': '나이도 성별도 상관없어요. 취향으로 만나요!',
        'min_year': 1981, // 45세
        'max_year': 2006, // 20세
        'split_gender': false,
      },
    ];

    for (final place in _hotPlaces) {
      final placeName = place['name'] as String;
      final lat = place['lat'] as double;
      final lng = place['lng'] as double;

      // 3 Partners per Hot Place
      for (var i = 0; i < 3; i++) {
        partnerCounter++;
        final partnerName = '$placeName 핫플 파트너 $i';
        final email = 'owner$partnerCounter@test.com';

        // Gender varies by partner to balance the owner pool
        final ownerId = await _createAdminUser(
          email: email,
          password: 'password1234!',
          metadata: {
            'name': '사장님 $partnerCounter ($placeName)',
            'username': 'owner_$partnerCounter',
            'gender': i.isEven ? 'male' : 'female',
            'birth_date': '1990-01-01',
            'phone_number': '010-9999-$partnerCounter',
          },
        );

        final partnerId = await _createPartner(
          ownerId,
          partnerName,
          '$placeName에서 가장 감각적인 공간, $partnerName입니다.',
          'Minglit Corp $partnerCounter',
          '123-45-$partnerCounter',
          email,
        );

        // Random Location
        final rLat = lat + (DateTime.now().microsecond % 20 - 10) * 0.0005;
        final rLng = lng + (DateTime.now().microsecond % 20 - 10) * 0.0005;

        final locationId = await _createLocation(
          partnerId,
          '$partnerName 본점',
          '$placeName 번화가 ${i + 1}길',
          rLat,
          rLng,
        );

        // 2 Parties per Partner (Cycle through scenarios)
        for (var p = 0; p < 2; p++) {
          final scenarioIndex = (partnerCounter + p) % scenarios.length;
          final scenario = scenarios[scenarioIndex];

          final baseTitle = (scenario['titles'] as List)[p % 3];
          final fullTitle = '[$placeName] $baseTitle';
          final splitGender = scenario['split_gender'] as bool;
          final minYear = scenario['min_year'] as int;
          final maxYear = scenario['max_year'] as int;

          // Construct Entry Groups & Tickets
          final entryGroups = <Map<String, dynamic>>[];
          final tickets = <Map<String, dynamic>>[];

          if (splitGender) {
            // Group 0: Male
            entryGroups.add({
              'label': '남성 입장',
              'gender': 'male',
              'birth_year_range': {'min': minYear, 'max': maxYear},
              'use_global_ids': [0], // Identity Verification
            });
            // Group 1: Female
            entryGroups.add({
              'label': '여성 입장',
              'gender': 'female',
              'birth_year_range': {
                'min': minYear,
                'max': maxYear,
              }, // Can adjust for lady first
              'use_global_ids': [0],
            });

            // Tickets linked to groups
            tickets.add({
              'name': '남성 입장권',
              'price': 35000,
              'quantity': 15,
              'group_index': 0, // Links to Male Group
            });
            tickets.add({
              'name': '여성 입장권',
              'price': 15000, // Ladies discount (common in KR)
              'quantity': 15,
              'group_index': 1, // Links to Female Group
            });
          } else {
            // Mixed Group
            entryGroups.add({
              'label': '일반 입장',
              'gender': null, // Mixed
              'birth_year_range': {'min': minYear, 'max': maxYear},
              'use_global_ids': [0],
            });

            tickets.add({
              'name': '일반 입장권',
              'price': 20000,
              'quantity': 30,
              'group_index': 0,
            });
          }

          final partyData = {
            'title': fullTitle,
            'description': _generateRichDescription(
              fullTitle,
              '${scenario['desc_header']}\n멋진 인연을 만들어보세요.',
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
