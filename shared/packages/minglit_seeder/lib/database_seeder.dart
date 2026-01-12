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

    for (final place in _hotPlaces) {
      final placeName = place['name'] as String;
      final lat = place['lat'] as double;
      final lng = place['lng'] as double;

      // 3. Partners per Hot Place
      for (var i = 0; i < 3; i++) {
        partnerCounter++;
        final partnerName = '$placeName 핫플 파트너 $i';
        final email = 'owner$partnerCounter@test.com';

        final ownerId = await _createAdminUser(
          email: email,
          password: 'password1234!',
          metadata: {
            'name': '사장님 $partnerCounter ($placeName)',
            'username': 'owner_$partnerCounter',
            'gender': i.isEven ? 'male' : 'female',
          },
        );

        final partnerId = await _createPartner(
          ownerId,
          partnerName,
          '$placeName에서 가장 핫한 라운지입니다.',
          'Minglit Corp $partnerCounter',
          '123-45-$partnerCounter',
          email,
        );

        // Random Location near Hot Place (approx 1km radius)
        // 0.01 degree approx 1.1km
        final rLat = lat + (DateTime.now().microsecond % 20 - 10) * 0.0005;
        final rLng = lng + (DateTime.now().microsecond % 20 - 10) * 0.0005;

        final locationId = await _createLocation(
          partnerId,
          '$partnerName 본점',
          '$placeName 번화가 ${i + 1}길',
          rLat,
          rLng,
        );

        // 2. Parties per Partner
        for (var p = 0; p < 2; p++) {
          final partyTitle = i == 0 ? '불금 와인 파티' : '주말 루프탑 모임';
          final fullTitle = '[$placeName] $partyTitle';
          final summary = '$placeName에서 가장 분위기 좋은 곳에서 새로운 사람들과 소중한 인연을 만들어보세요. '
              '전문 MC와 함께하는 즐거운 프로그램이 준비되어 있습니다.';

          final partyData = {
            'title': fullTitle,
            'description': _generateRichDescription(fullTitle, summary),
            'entry_groups': [
              {
                'label': '일반 입장',
                'gender': null,
                'birth_year_range': {'min': 1990, 'max': 2000},
                'use_global_ids': [0], // Identity Verification
                'use_local_indices': [],
              }
            ],
            'tickets': [
              {
                'name': 'Early Bird Ticket',
                'price': 15000,
                'quantity': 10,
                'group_index': 0
              },
              {
                'name': 'Regular Ticket',
                'price': 30000,
                'quantity': 30,
                'group_index': 0
              }
            ]
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
        {"insert": "✨ $title\n", "attributes": {"header": 1, "bold": true}},
        {"insert": "\n"},
        {"insert": "📍 파티 소개\n", "attributes": {"header": 2}},
        {"insert": "$summary\n\n"},
        {"insert": "🕒 타임테이블\n", "attributes": {"header": 2}},
        {"insert": "19:00 - 입장 및 웰컴 드링크\n", "attributes": {"list": "bullet"}},
        {"insert": "19:30 - 아이스브레이킹 게임 (어색함 타파!)\n", "attributes": {"list": "bullet"}},
        {"insert": "20:30 - 1:1 대화 로테이션 및 네트워킹\n", "attributes": {"list": "bullet"}},
        {"insert": "22:00 - 자유 대화 및 공식 행사 종료\n", "attributes": {"list": "bullet"}},
        {"insert": "\n"},
        {"insert": "✅ 제공 내역\n", "attributes": {"header": 2}},
        {"insert": "레드/화이트/스파클링 와인 무제한\n", "attributes": {"list": "bullet"}},
        {"insert": "프리미엄 핑거 푸드 케이터링\n", "attributes": {"list": "bullet"}},
        {"insert": "매칭 확률을 높여주는 Minglit 가이드북\n", "attributes": {"list": "bullet"}},
        {"insert": "\n"},
        {"insert": "📢 안내 사항\n", "attributes": {"header": 2}},
        {"insert": "신분증 지참 필수입니다. (PASS 인증 확인)\n", "attributes": {"bold": true}},
        {"insert": "과도한 음주는 삼가주세요.\n"},
      ]
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

    // Map Entry Groups
    final entryGroups =
        (partyData['entry_groups'] as List<dynamic>).map((dynamic g) {
      final gMap = g as Map<String, dynamic>;
      final groupUuid = const Uuid().v4();
      final requiredIds = <String>[];

      final globalIndices = gMap['use_global_ids'] as List<dynamic>? ?? [];
      for (final dynamic gi in globalIndices) {
        final idx = gi as int;
        if (globalVerifIds.length > idx) requiredIds.add(globalVerifIds[idx]);
      }

      final localIndices = gMap['use_local_indices'] as List<dynamic>? ?? [];
      for (final dynamic li in localIndices) {
        final idx = li as int;
        if (localVerifIds.length > idx) requiredIds.add(localVerifIds[idx]);
      }

      return {
        'id': groupUuid,
        'label': gMap['label'],
        'gender': gMap['gender'],
        'birth_year_range': gMap['birth_year_range'],
        'required_verification_ids': requiredIds,
      };
    }).toList();

    final allVerifIds = entryGroups
        .expand((e) => e['required_verification_ids'] as List)
        .toSet()
        .toList();

    await _adminClient.from('parties').insert({
      'id': partyId,
      'partner_id': partnerId,
      'location_id': locationId,
      'title': partyData['title'],
      'description': partyData['description'], // Now a Map
      'min_confirmed_count': 5,
      'max_participants': 20,
      'required_verification_ids': allVerifIds,
    });

    // Create Entry Group Templates
    final entryGroupTemplatesRes = await _adminClient.from('entry_group_templates').insert(
      entryGroups.map((g) => {
        'party_id': partyId,
        'label': g['label'],
        'gender': g['gender'],
        'birth_year_min': g['birth_year_range']?['min'],
        'birth_year_max': g['birth_year_range']?['max'],
        'required_verification_ids': g['required_verification_ids'],
      }).toList(),
    ).select('id');

    final templateIds = (entryGroupTemplatesRes as List).map((e) => e['id'] as String).toList();

    // Create Ticket Templates (Use actual Entry Group Template IDs)
    final tickets = partyData['tickets'] as List<dynamic>? ?? [];
    await _adminClient.from('ticket_templates').insert(
      tickets.map((dynamic t) {
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

    // Create Events (Instances)
    final now = DateTime.now();
    final eventDates = [
      now.add(const Duration(hours: 3)),
      now.add(const Duration(days: 7)),
      now.add(const Duration(days: 8)),
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

      // Create Event Entry Groups
      final eventGroupsRes = await _adminClient.from('entry_groups').insert(
        entryGroups.map((g) => {
          'event_id': eventId,
          'label': g['label'],
          'gender': g['gender'],
          'birth_year_min': g['birth_year_range']?['min'],
          'birth_year_max': g['birth_year_range']?['max'],
          'required_verification_ids': g['required_verification_ids'],
        }).toList(),
      ).select('id');

      final eventGroupIds = (eventGroupsRes as List).map((e) => e['id'] as String).toList();

      // Create Event Tickets (Link to Event Entry Groups)
      await _adminClient.from('tickets').insert(
        tickets.map((dynamic t) {
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
