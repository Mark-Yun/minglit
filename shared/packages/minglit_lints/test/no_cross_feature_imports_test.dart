import 'package:minglit_lints/src/no_cross_feature_imports_rule.dart';
import 'package:test/test.dart';

void main() {
  group('NoCrossFeatureImportsRule.isCrossFeatureImport', () {
    // -----------------------------------------------------------------------
    // Positive cases — should be flagged
    // -----------------------------------------------------------------------
    group('positive: cross-feature imports within the same app', () {
      test('app_user: home imports from tag feature', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/Users/dev/minglit/apps/app_user/lib/src/features/home/widgets/featured_tag_chip_bar.dart',
            importUri: 'package:app_user/src/features/tag/widgets/tag_chip.dart',
          ),
          isTrue,
        );
      });

      test('app_user: event imports from auth feature', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/event/admission/event_admission_controller.dart',
            importUri:
                'package:app_user/src/features/auth/repositories/auth_repository.dart',
          ),
          isTrue,
        );
      });

      test('app_user: my_tickets imports from ticket feature', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/my_tickets/ui/my_tickets_page.dart',
            importUri:
                'package:app_user/src/features/ticket/ui/ticket_card.dart',
          ),
          isTrue,
        );
      });

      test('app_partner: application imports from party feature', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_partner/lib/src/features/application/event_application_detail_page.dart',
            importUri:
                'package:app_partner/src/features/party/repositories/party_repository.dart',
          ),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Negative cases — should NOT be flagged
    // -----------------------------------------------------------------------
    group('negative: imports that should be allowed', () {
      test('same-feature import within app_user', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/home/widgets/home_banner.dart',
            importUri:
                'package:app_user/src/features/home/view_models/home_view_model.dart',
          ),
          isFalse,
        );
      });

      test('same-feature import within app_partner', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_partner/lib/src/features/checkin/ui/checkin_page.dart',
            importUri:
                'package:app_partner/src/features/checkin/widgets/checkin_scanner_overlay.dart',
          ),
          isFalse,
        );
      });

      test('import from minglit_kit (shared package)', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/home/widgets/event_card.dart',
            importUri:
                'package:minglit_kit/src/ui/widgets/party/event_card.dart',
          ),
          isFalse,
        );
      });

      test('import from third-party package', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/home/home_page.dart',
            importUri: 'package:flutter/material.dart',
          ),
          isFalse,
        );
      });

      test('file outside features directory is not flagged', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/common/widgets/loading_widget.dart',
            importUri:
                'package:app_user/src/features/home/widgets/home_banner.dart',
          ),
          isFalse,
        );
      });

      test('app_user file importing app_partner feature is not flagged', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/home/home_page.dart',
            importUri:
                'package:app_partner/src/features/checkin/widgets/qr_overlay.dart',
          ),
          isFalse,
        );
      });

      test('relative import (no package: prefix) is not flagged', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/home/home_page.dart',
            importUri: '../tag/widgets/tag_chip.dart',
          ),
          isFalse,
        );
      });

      test('dart:core import is not flagged', () {
        expect(
          NoCrossFeatureImportsRule.isCrossFeatureImport(
            currentFilePath:
                '/apps/app_user/lib/src/features/home/home_page.dart',
            importUri: 'dart:async',
          ),
          isFalse,
        );
      });
    });
  });
}
