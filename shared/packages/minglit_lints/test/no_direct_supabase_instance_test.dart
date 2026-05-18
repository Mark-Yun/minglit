import 'package:minglit_lints/src/no_direct_supabase_instance.dart';
import 'package:test/test.dart';

void main() {
  group('NoDirectSupabaseInstanceRule.isExemptPath', () {
    // -----------------------------------------------------------------------
    // Positive exempt cases — should NOT be flagged
    // -----------------------------------------------------------------------
    group('exempt paths: no warning expected', () {
      test('repository implementation in minglit_kit', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/Users/dev/minglit/shared/packages/minglit_kit/lib/src/data/repositories/auth_repository.dart',
          ),
          isTrue,
        );
      });

      test('nested repository sub-directory in minglit_kit', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/data/repositories/event/event_repository.dart',
          ),
          isTrue,
        );
      });

      test('supabase_provider.dart — the wrapping provider itself', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/logic/providers/supabase_provider.dart',
          ),
          isTrue,
        );
      });

      test('dev feature file in minglit_kit', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/features/dev/debug_panel.dart',
          ),
          isTrue,
        );
      });

      test('unit test file', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/apps/app_user/test/repositories/auth_repository_test.dart',
          ),
          isTrue,
        );
      });

      test('integration_test file', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/apps/app_user/integration_test/cuj/login_cuj_test.dart',
          ),
          isTrue,
        );
      });

      test('patrol_test file', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/apps/app_user/patrol_test/smoke_test.dart',
          ),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Non-exempt cases — warning SHOULD fire
    // -----------------------------------------------------------------------
    group('non-exempt paths: warning expected', () {
      test('logic provider (not supabase_provider.dart) in minglit_kit', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/logic/providers/user_provider.dart',
          ),
          isFalse,
        );
      });

      test('feature controller in minglit_kit', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/features/event/logic/event_controller.dart',
          ),
          isFalse,
        );
      });

      test('app_user feature file', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/apps/app_user/lib/src/features/home/data/home_repository.dart',
          ),
          isFalse,
        );
      });

      test('app_partner feature file', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/apps/app_partner/lib/src/features/checkin/data/checkin_repository.dart',
          ),
          isFalse,
        );
      });

      test('service file outside repositories', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/data/services/bug_report_collector.dart',
          ),
          isFalse,
        );
      });

      test('social interaction controller', () {
        expect(
          NoDirectSupabaseInstanceRule.isExemptPath(
            '/project/shared/packages/minglit_kit/lib/src/features/social/logic/social_interaction_controller.dart',
          ),
          isFalse,
        );
      });
    });
  });

  // -------------------------------------------------------------------------
  // AST helper: _isSupabaseInstanceAccess is package-private, so we test the
  // path-exemption logic only (AST visitor integration is covered by the
  // lint integration tests run via `dart run custom_lint`).
  // -------------------------------------------------------------------------
}
