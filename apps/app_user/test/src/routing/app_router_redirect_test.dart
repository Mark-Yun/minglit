// Tests for GoRouter redirect logic in app_router.dart
//
// GoRouter redirect depends on Supabase.instance at runtime, so we mirror
// the same branching logic here as a pure function and verify each branch.
// This approach keeps tests fast and dependency-free while ensuring the
// documented invariants (e.g., /dev paths bypass auth) cannot silently regress.
//
// SYNC REQUIREMENT: _redirect() below mirrors `app_router.dart` → `goRouter`
// → `redirect`. app_router.dart의 redirect 분기를 수정하면 반드시 이 파일의
// _redirect()도 동일하게 업데이트해야 한다. 미동기화 시 테스트가 실제 동작과
// 달라져 false-positive가 발생한다.

import 'package:flutter_test/flutter_test.dart';

/// IMPORTANT: This function mirrors the redirect logic in
/// `lib/src/routing/app_router.dart` → `goRouter` → `redirect`.
/// When modifying redirect branches in app_router.dart, update this
/// mirror accordingly. See also: edge_cases_test.dart for widget-level
/// integration tests of the same routes.
///
/// Returns the redirect destination, or `null` when no redirect is needed.
/// Covers redirect branches 1–3 from `app_router.dart` (auth + protected
/// path guards). The mirror is intentionally partial — see scope note below.
///
/// Note: consent 상태 관련 분기(redirect 분기 4~6)는 Supabase 의존성이
/// 필요하여 이 순수 함수 테스트에서는 생략. 해당 분기는 integration test에서 검증.
///
/// [location] mirrors `state.uri.toString()` — the full URI including query
/// parameters (e.g. `/events/abc/apply?source=share`). [path] is derived
/// from [location] internally, matching `state.uri.path` in app_router.dart.
String? _redirect({
  required String location,
  required bool isLoggedIn,
}) {
  final uri = Uri.parse(location);
  final path = uri.path;
  final queryParameters = uri.queryParameters;

  // Redirect /explore deep links to home (backward compat)
  // Fix #1701: minglit://explore/... comes in as host='explore', path='/*'
  if (path.startsWith('/explore') || uri.host == 'explore') return '/';

  // Allow dev pages without authentication
  if (path.startsWith('/dev')) return null;

  final isLoggingIn = path == '/login';

  // 1. Already logged in, going to /login -> original destination or home
  if (isLoggedIn && isLoggingIn) {
    final from = queryParameters['from'];
    if (from != null && from.startsWith('/') && !from.startsWith('//')) {
      // Mirror _sanitizeReturnLocation: parse URI and check path == '/login'
      // (exact match, not startsWith — avoids blocking /login-help, /login/callback)
      final fromPath = Uri.tryParse(from)?.path ?? from;
      if (fromPath != '/login') return from;
    }
    return '/';
  }

  // 2. Protected prefixes (login required)
  // prefix-match: 이 경로로 시작하는 모든 진입은 로그인을 요구함
  const protectedPrefixes = [
    '/my', // 마이페이지, 알림 설정 (/my/notification-settings)
    '/tickets/my', // 내 티켓 목록
    '/payment', // 결제 관련
    '/purchase-history', // 구매 내역
    '/certification', // 본인인증
    '/signup/consent', // 필수 동의
  ];

  // suffix-match: /apply (이벤트 신청), /qr (개인 티켓 QR — 인증 필수)
  // Fix #1072: /qr 보호 추가 — 개인 티켓 QR은 로그인 없이 접근 불가
  final isProtected =
      protectedPrefixes.any(path.startsWith) ||
      path.endsWith('/apply') ||
      path.endsWith('/qr') ||
      path.endsWith('/matching');

  // 3. Unauthenticated access to a protected path -> /login?from=<full location>
  // Fix #1249: location (full URI) instead of path to preserve query params
  if (!isLoggedIn && isProtected) {
    return Uri(
      path: '/login',
      queryParameters: {'from': location},
    ).toString();
  }

  return null;
}

void main() {
  // ---------------------------------------------------------------------------
  // /dev/* — auth bypass (Issue #1249)
  // ---------------------------------------------------------------------------
  group('/dev paths — auth bypass', () {
    test('/dev/switch returns null (no redirect) when not logged in', () {
      final result = _redirect(location: '/dev/switch', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/dev/switch returns null (no redirect) when logged in', () {
      final result = _redirect(location: '/dev/switch', isLoggedIn: true);
      expect(result, isNull);
    });

    test('/dev returns null (no redirect) when not logged in', () {
      final result = _redirect(location: '/dev', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/dev/any-sub-path returns null (no redirect)', () {
      final result = _redirect(
        location: '/dev/some-other-tool',
        isLoggedIn: false,
      );
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // /explore — backward compat redirect
  // ---------------------------------------------------------------------------
  group('/explore paths — redirect to home', () {
    test('/explore redirects to /', () {
      final result = _redirect(location: '/explore', isLoggedIn: false);
      expect(result, '/');
    });

    test('/explore/something redirects to /', () {
      final result = _redirect(
        location: '/explore/something',
        isLoggedIn: false,
      );
      expect(result, '/');
    });

    // Fix #1701: Android intent delivers minglit://explore/events as a URI
    // where host='explore' and path='/events', bypassing the path check above.
    test('minglit://explore/events (scheme URL) redirects to /', () {
      final result = _redirect(
        location: 'minglit://explore/events',
        isLoggedIn: false,
      );
      expect(result, '/');
    });

    test('minglit://explore/curation (scheme URL) redirects to /', () {
      final result = _redirect(
        location: 'minglit://explore/curation',
        isLoggedIn: false,
      );
      expect(result, '/');
    });
  });

  // ---------------------------------------------------------------------------
  // Protected paths — require authentication
  // ---------------------------------------------------------------------------
  group('protected paths — unauthenticated', () {
    test('/my redirects to /login?from=/my when not logged in', () {
      final result = _redirect(location: '/my', isLoggedIn: false);
      expect(result, '/login?from=%2Fmy');
    });

    test('/events/:id/apply redirects to /login when not logged in', () {
      final result = _redirect(
        location: '/events/event-123/apply',
        isLoggedIn: false,
      );
      expect(result, '/login?from=%2Fevents%2Fevent-123%2Fapply');
    });

    test('/purchase-history redirects to /login when not logged in', () {
      final result = _redirect(
        location: '/purchase-history',
        isLoggedIn: false,
      );
      expect(result, '/login?from=%2Fpurchase-history');
    });

    test('/signup/consent redirects to /login when not logged in', () {
      final result = _redirect(location: '/signup/consent', isLoggedIn: false);
      expect(result, '/login?from=%2Fsignup%2Fconsent');
    });

    test('/events/:id/qr redirects to /login when not logged in', () {
      final result = _redirect(
        location: '/events/event-123/qr',
        isLoggedIn: false,
      );
      expect(result, '/login?from=%2Fevents%2Fevent-123%2Fqr');
    });

    test('/events/:id/matching redirects to /login when not logged in', () {
      final result = _redirect(
        location: '/events/event-123/matching',
        isLoggedIn: false,
      );
      expect(result, '/login?from=%2Fevents%2Fevent-123%2Fmatching');
    });

    // Fix #1249: query parameters in the original location must be preserved
    // in the `from` param so the user returns to the exact same page after login.
    test(
      '/events/:id/apply with query params — full URI preserved in from param',
      () {
        final result = _redirect(
          location: '/events/abc/apply?source=share',
          isLoggedIn: false,
        );
        // from value must be the full URI (path + query), percent-encoded
        expect(
          result,
          '/login?from=%2Fevents%2Fabc%2Fapply%3Fsource%3Dshare',
        );
      },
    );
  });

  group('protected paths — authenticated', () {
    test('/my returns null when logged in', () {
      final result = _redirect(location: '/my', isLoggedIn: true);
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // /login — already logged-in behavior
  // ---------------------------------------------------------------------------
  group('/login — already authenticated', () {
    test('redirects to / when no from param', () {
      final result = _redirect(location: '/login', isLoggedIn: true);
      expect(result, '/');
    });

    test('redirects to from param when valid', () {
      final result = _redirect(
        location: '/login?from=%2Fevents%2Fabc',
        isLoggedIn: true,
      );
      expect(result, '/events/abc');
    });

    test('ignores from=/login to prevent redirect loop', () {
      final result = _redirect(
        location: '/login?from=%2Flogin',
        isLoggedIn: true,
      );
      expect(result, '/');
    });

    test('ignores from=// to prevent external redirect', () {
      final result = _redirect(
        location: '/login?from=%2F%2Fevil.com',
        isLoggedIn: true,
      );
      expect(result, '/');
    });

    // Fix #1249: /login-help는 /login과 다른 경로 — 정확히 '/login'인 경우만 차단
    test('allows from=/login-help (exact match, not prefix)', () {
      final result = _redirect(
        location: '/login?from=%2Flogin-help',
        isLoggedIn: true,
      );
      expect(result, '/login-help');
    });
  });

  // ---------------------------------------------------------------------------
  // Public paths — no redirect
  // ---------------------------------------------------------------------------
  group('public paths — no redirect', () {
    test('/ returns null', () {
      final result = _redirect(location: '/', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/events/:id returns null', () {
      final result = _redirect(location: '/events/abc123', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/search returns null', () {
      final result = _redirect(location: '/search', isLoggedIn: false);
      expect(result, isNull);
    });
  });
}
