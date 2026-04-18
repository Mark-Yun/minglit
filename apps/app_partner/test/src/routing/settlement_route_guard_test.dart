// Fix #1533: settlement 라우트 가드 회귀 테스트.
// UI 숨김(PartnerScaffold)만으로는 딥링크/직접 접근을 막지 못하므로,
// GoRouter redirect에서도 SETTLEMENT_VIEW 권한을 확인하는 경로를 검증한다.
//
// SYNC REQUIREMENT: _redirectSettlement() 아래는 app_router.dart 의
// settlement 가드 분기(redirect 4번)를 미러한다. app_router.dart를 수정하면
// 반드시 이 파일도 같이 업데이트해야 한다.
import 'package:flutter_test/flutter_test.dart';

/// Mirrors redirect branch 4 from app_router.dart (settlement route guard).
///
/// [path] mirrors `state.uri.path`.
/// [isLoggedIn] mirrors `ref.read(currentUserProvider) != null`.
/// [hasSettlementAccess] mirrors `ref.read(hasSettlementAccessProvider).maybeWhen(...)`.
///
/// Returns '/' when access should be denied, null otherwise.
String? _redirectSettlement({
  required String path,
  required bool isLoggedIn,
  required bool hasSettlementAccess,
}) {
  if (!isLoggedIn) return null; // auth guard handles this before settlement
  if (!path.startsWith('/settlement')) return null;
  if (!hasSettlementAccess) return '/';
  return null;
}

void main() {
  group('Settlement route guard — redirect branch 4', () {
    // --- blocked cases ---

    test('/settlement → / when no SETTLEMENT_VIEW permission', () {
      final result = _redirectSettlement(
        path: '/settlement',
        isLoggedIn: true,
        hasSettlementAccess: false,
      );
      expect(
        result,
        '/',
        reason: 'staff without SETTLEMENT_VIEW must be redirected to home',
      );
    });

    test('/settlement/bank-account → / when no permission', () {
      final result = _redirectSettlement(
        path: '/settlement/bank-account',
        isLoggedIn: true,
        hasSettlementAccess: false,
      );
      expect(result, '/');
    });

    test('/settlement/some-id → / when no permission', () {
      final result = _redirectSettlement(
        path: '/settlement/some-id-123',
        isLoggedIn: true,
        hasSettlementAccess: false,
      );
      expect(result, '/');
    });

    // fail-closed: loading/error state returns false → blocked
    test('/settlement → / when settlement access is loading (fail-closed)', () {
      // hasSettlementAccess = false mimics maybeWhen(orElse: () => false)
      final result = _redirectSettlement(
        path: '/settlement',
        isLoggedIn: true,
        hasSettlementAccess: false,
      );
      expect(result, '/');
    });

    // --- allowed cases ---

    test('/settlement → null (allowed) when user has SETTLEMENT_VIEW', () {
      final result = _redirectSettlement(
        path: '/settlement',
        isLoggedIn: true,
        hasSettlementAccess: true,
      );
      expect(
        result,
        isNull,
        reason: 'owner/manager with SETTLEMENT_VIEW must reach settlement',
      );
    });

    test('/settlement/bank-account → null when user has SETTLEMENT_VIEW', () {
      final result = _redirectSettlement(
        path: '/settlement/bank-account',
        isLoggedIn: true,
        hasSettlementAccess: true,
      );
      expect(result, isNull);
    });

    // --- guard does not affect non-settlement routes ---

    test('/more → null (not affected by settlement guard)', () {
      final result = _redirectSettlement(
        path: '/more',
        isLoggedIn: true,
        hasSettlementAccess: false,
      );
      expect(result, isNull);
    });

    test('/ → null (not affected by settlement guard)', () {
      final result = _redirectSettlement(
        path: '/',
        isLoggedIn: true,
        hasSettlementAccess: false,
      );
      expect(result, isNull);
    });

    // --- unauthenticated: settlement guard defers to auth guard ---
    test('/settlement → null when not logged in (auth guard handles it)', () {
      final result = _redirectSettlement(
        path: '/settlement',
        isLoggedIn: false,
        hasSettlementAccess: false,
      );
      expect(
        result,
        isNull,
        reason: 'auth guard (branch 1) fires first for unauthenticated users',
      );
    });
  });
}
