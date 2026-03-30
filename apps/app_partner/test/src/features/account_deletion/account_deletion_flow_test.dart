import 'package:app_partner/src/features/account_deletion/account_deletion_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('buildWithdrawalReason', () {
    test('normalizes blank detail to null', () {
      final reason = buildWithdrawalReason(
        reasonCode: 'other',
        reasonText: '   ',
      );

      expect(reason, isNotNull);
      expect(reason!.reasonCode, WithdrawalReasonCode.other);
      expect(reason.detail, isNull);
    });
  });

  group('usesPasswordAuth', () {
    test('returns has_password metadata flag', () {
      final user = User(
        id: 'user-1',
        appMetadata: const {'has_password': true},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );

      expect(usesPasswordAuth(user), isTrue);
    });

    test('defaults to false when metadata flag is absent', () {
      final user = User(
        id: 'user-1',
        appMetadata: const {'provider': 'email'},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime(2026).toIso8601String(),
      );

      expect(usesPasswordAuth(user), isFalse);
    });
  });
}
