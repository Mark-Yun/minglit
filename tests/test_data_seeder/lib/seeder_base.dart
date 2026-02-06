part of 'database_seeder.dart';

mixin _SeederBase on _SeederContext {
  Future<List<String>> _getGlobalVerificationIds() async {
    final result = await adminClient
        .from('verifications')
        .select('id')
        .filter('partner_id', 'is', null);

    return (result as List)
        .map((dynamic e) => (e as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Map<String, dynamic> _generateRichDescription(String title, String summary) {
    return {
      'ops': [
        {
          'insert': '✨ $title\n',
          'attributes': {'header': 1, 'bold': true},
        },
        {'insert': '\n'},
        {
          'insert': '📍 파티 소개\n',
          'attributes': {'header': 2},
        },
        {'insert': '$summary\n\n'},
        {
          'insert': '🕒 타임테이블\n',
          'attributes': {'header': 2},
        },
        {
          'insert': '19:00 - 입장 및 웰컴 드링크\n',
          'attributes': {'list': 'bullet'},
        },
        {
          'insert': '19:30 - 아이스브레이킹 게임 (어색함 타파!)\n',
          'attributes': {'list': 'bullet'},
        },
        {
          'insert': '20:30 - 1:1 대화 로테이션 및 네트워킹\n',
          'attributes': {'list': 'bullet'},
        },
        {
          'insert': '22:00 - 자유 대화 및 공식 행사 종료\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': '\n'},
        {
          'insert': '✅ 제공 내역\n',
          'attributes': {'header': 2},
        },
        {
          'insert': '레드/화이트/스파클링 와인 무제한\n',
          'attributes': {'list': 'bullet'},
        },
        {
          'insert': '프리미엄 핑거 푸드 케이터링\n',
          'attributes': {'list': 'bullet'},
        },
        {
          'insert': '매칭 확률을 높여주는 Minglit 가이드북\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': '\n'},
        {
          'insert': '📢 안내 사항\n',
          'attributes': {'header': 2},
        },
        {
          'insert': '신분증 지참 필수입니다. (PASS 인증 확인)\n',
          'attributes': {'bold': true},
        },
        {'insert': '과도한 음주는 삼가주세요.\n'},
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
    final partnerRes = await adminClient
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

    await adminClient.from('partner_member_permissions').insert({
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
    final locationRes = await adminClient
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

  Future<String> _createAdminUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final res = await adminClient.auth.admin.createUser(
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
        final usersRes = await adminClient.auth.admin.listUsers(perPage: 1000);
        try {
          final existing = usersRes.firstWhere((u) => u.email == email);
          await adminClient.auth.admin.deleteUser(existing.id);
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
