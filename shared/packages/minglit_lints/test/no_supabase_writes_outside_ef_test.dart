import 'package:minglit_lints/src/no_supabase_writes_outside_ef_rule.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // isWriteMethodName
  // ---------------------------------------------------------------------------
  group('NoSupabaseWritesOutsideEfRule.isWriteMethodName', () {
    group('positive: write method names', () {
      test('insert', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('insert'), isTrue));
      test('update', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('update'), isTrue));
      test('delete', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('delete'), isTrue));
      test('upsert', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('upsert'), isTrue));
    });

    group('negative: non-write method names', () {
      test('select', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('select'), isFalse));
      test('from', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('from'), isFalse));
      test('invoke', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('invoke'), isFalse));
      test('eq', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('eq'), isFalse));
      test('filter', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('filter'), isFalse));
      test('rpc', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName('rpc'), isFalse));
      test('empty string', () => expect(NoSupabaseWritesOutsideEfRule.isWriteMethodName(''), isFalse));
    });
  });

  // ---------------------------------------------------------------------------
  // matchesAllowlistComment
  // ---------------------------------------------------------------------------
  group('NoSupabaseWritesOutsideEfRule.matchesAllowlistComment', () {
    group('positive: valid suppression comments', () {
      test('standard em-dash format with reason', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// minglit_lints: allow-supabase-write — reason: EF migration pending until 2026-07-01',
          ),
          isTrue,
        );
      });

      test('reason with colon only (minimal)', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// minglit_lints: allow-supabase-write — reason: legacy write path',
          ),
          isTrue,
        );
      });

      test('reason without em-dash separator is still matched', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// minglit_lints: allow-supabase-write reason: workaround for #1234',
          ),
          isTrue,
        );
      });
    });

    group('negative: invalid or missing suppression', () {
      test('marker present but reason: key missing', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// minglit_lints: allow-supabase-write — migration in progress',
          ),
          isFalse,
        );
      });

      test('marker present but reason value is empty', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// minglit_lints: allow-supabase-write — reason:',
          ),
          isFalse,
        );
      });

      test('reason value is only whitespace', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// minglit_lints: allow-supabase-write — reason:   ',
          ),
          isFalse,
        );
      });

      test('unrelated comment', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// TODO: migrate to EF',
          ),
          isFalse,
        );
      });

      test('missing minglit_lints prefix', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// allow-supabase-write — reason: old code',
          ),
          isFalse,
        );
      });

      test('empty string', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(''),
          isFalse,
        );
      });

      test('ignore comment', () {
        expect(
          NoSupabaseWritesOutsideEfRule.matchesAllowlistComment(
            '// ignore: no_supabase_writes_outside_ef',
          ),
          isFalse,
        );
      });
    });
  });
}
