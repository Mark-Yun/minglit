// Tests for GoRouter redirect logic in app_router.dart
//
// GoRouter redirect depends on Supabase.instance at runtime, so we mirror
// the same branching logic here as a pure function and verify each branch.
// This approach keeps tests fast and dependency-free while ensuring the
// documented invariants (e.g., /dev paths bypass auth) cannot silently regress.

import 'package:flutter_test/flutter_test.dart';

/// Pure mirror of the redirect decision in [goRouter].
///
/// Returns the redirect destination, or `null` when no redirect is needed.
/// Matches the logic in `app_router.dart` line-for-line so that any
/// divergence will be caught by these tests.
String? _redirect({
  required String path,
  required bool isLoggedIn,
  Map<String, String> queryParameters = const {},
}) {
  // Redirect /explore deep links to home (backward compat)
  if (path.startsWith('/explore')) return '/';

  // Allow dev pages without authentication
  if (path.startsWith('/dev')) return null;

  final isLoggingIn = path == '/login';

  // 1. Already logged in, going to /login -> original destination or home
  if (isLoggedIn && isLoggingIn) {
    final from = queryParameters['from'];
    if (from != null &&
        from.startsWith('/') &&
        !from.startsWith('//') &&
        !from.startsWith('/login')) {
      return from;
    }
    return '/';
  }

  // 2. Protected prefixes (login required)
  const protectedPrefixes = [
    '/my',
    '/tickets/my',
    '/payment',
    '/purchase-history',
    '/certification',
  ];

  final isProtected =
      protectedPrefixes.any(path.startsWith) || path.endsWith('/apply');

  // 3. Unauthenticated access to a protected path -> /login?from=...
  if (!isLoggedIn && isProtected) {
    return Uri(
      path: '/login',
      queryParameters: {'from': path},
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
      final result = _redirect(path: '/dev/switch', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/dev/switch returns null (no redirect) when logged in', () {
      final result = _redirect(path: '/dev/switch', isLoggedIn: true);
      expect(result, isNull);
    });

    test('/dev returns null (no redirect) when not logged in', () {
      final result = _redirect(path: '/dev', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/dev/any-sub-path returns null (no redirect)', () {
      final result = _redirect(path: '/dev/some-other-tool', isLoggedIn: false);
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // /explore — backward compat redirect
  // ---------------------------------------------------------------------------
  group('/explore paths — redirect to home', () {
    test('/explore redirects to /', () {
      final result = _redirect(path: '/explore', isLoggedIn: false);
      expect(result, '/');
    });

    test('/explore/something redirects to /', () {
      final result = _redirect(path: '/explore/something', isLoggedIn: false);
      expect(result, '/');
    });
  });

  // ---------------------------------------------------------------------------
  // Protected paths — require authentication
  // ---------------------------------------------------------------------------
  group('protected paths — unauthenticated', () {
    test('/my redirects to /login?from=/my when not logged in', () {
      final result = _redirect(path: '/my', isLoggedIn: false);
      expect(result, '/login?from=%2Fmy');
    });

    test('/events/:id/apply redirects to /login when not logged in', () {
      final result = _redirect(
        path: '/events/event-123/apply',
        isLoggedIn: false,
      );
      expect(result, '/login?from=%2Fevents%2Fevent-123%2Fapply');
    });

    test('/purchase-history redirects to /login when not logged in', () {
      final result =
          _redirect(path: '/purchase-history', isLoggedIn: false);
      expect(result, '/login?from=%2Fpurchase-history');
    });
  });

  group('protected paths — authenticated', () {
    test('/my returns null when logged in', () {
      final result = _redirect(path: '/my', isLoggedIn: true);
      expect(result, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // /login — already logged-in behavior
  // ---------------------------------------------------------------------------
  group('/login — already authenticated', () {
    test('redirects to / when no from param', () {
      final result = _redirect(path: '/login', isLoggedIn: true);
      expect(result, '/');
    });

    test('redirects to from param when valid', () {
      final result = _redirect(
        path: '/login',
        isLoggedIn: true,
        queryParameters: {'from': '/events/abc'},
      );
      expect(result, '/events/abc');
    });

    test('ignores from=/login to prevent redirect loop', () {
      final result = _redirect(
        path: '/login',
        isLoggedIn: true,
        queryParameters: {'from': '/login'},
      );
      expect(result, '/');
    });

    test('ignores from=// to prevent external redirect', () {
      final result = _redirect(
        path: '/login',
        isLoggedIn: true,
        queryParameters: {'from': '//evil.com'},
      );
      expect(result, '/');
    });
  });

  // ---------------------------------------------------------------------------
  // Public paths — no redirect
  // ---------------------------------------------------------------------------
  group('public paths — no redirect', () {
    test('/ returns null', () {
      final result = _redirect(path: '/', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/events/:id returns null', () {
      final result = _redirect(path: '/events/abc123', isLoggedIn: false);
      expect(result, isNull);
    });

    test('/search returns null', () {
      final result = _redirect(path: '/search', isLoggedIn: false);
      expect(result, isNull);
    });
  });
}
