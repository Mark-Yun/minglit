part of 'database_seeder.dart';

mixin SeederParties on _SeederContext, SeederBase, SeederEvents {
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
        final localVerifRes = await adminClient
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
}
