import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/test_utils.dart';

void main() {
  group('PartnerApplyValidation', () {
    test('validateStep(0) returns false when brandName is empty', () {
      final container = createContainer(
        overrides: [
          // Keep the controller isolated — no network calls in these tests
          partnerApplyControllerProvider.overrideWith(
            PartnerApplyController.new,
          ),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      expect(notifier.validateStep(0), isFalse);
    });

    test('validateStep(0) returns true when brandName is set', () {
      final container = createContainer(
        overrides: [
          partnerApplyControllerProvider.overrideWith(
            PartnerApplyController.new,
          ),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);
      notifier.updateField('brandName', 'My Brand');

      expect(notifier.validateStep(0), isTrue);
    });

    test('validateStep(1) requires bizName, bizNumber, representativeName', () {
      final container = createContainer(
        overrides: [
          partnerApplyControllerProvider.overrideWith(
            PartnerApplyController.new,
          ),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      // Partial fill — missing representativeName
      notifier
        ..updateField('bizName', 'Biz Corp')
        ..updateField('bizNumber', '123-45-67890');

      expect(notifier.validateStep(1), isFalse);

      notifier.updateField('representativeName', 'John Doe');
      expect(notifier.validateStep(1), isTrue);
    });

    test('validateStep(2) requires all contact and bank fields', () {
      final container = createContainer(
        overrides: [
          partnerApplyControllerProvider.overrideWith(
            PartnerApplyController.new,
          ),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      expect(notifier.validateStep(2), isFalse);

      notifier
        ..updateField('contactPhone', '010-1234-5678')
        ..updateField('contactEmail', 'biz@example.com')
        ..updateField('bankName', 'Kookmin')
        ..updateField('accountNumber', '123456789')
        ..updateField('accountHolder', 'John Doe');

      expect(notifier.validateStep(2), isTrue);
    });

    test('validateStep for unknown step returns false', () {
      final container = createContainer(
        overrides: [
          partnerApplyControllerProvider.overrideWith(
            PartnerApplyController.new,
          ),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      expect(notifier.validateStep(99), isFalse);
    });

    test('validateAll returns false when required file paths are missing', () {
      final container = createContainer(
        overrides: [
          partnerApplyControllerProvider.overrideWith(
            PartnerApplyController.new,
          ),
        ],
      );

      final notifier = container.read(partnerApplyControllerProvider.notifier);

      expect(notifier.validateAll(), isFalse);

      notifier
        ..updateField('brandName', 'My Brand')
        ..updateField('bizName', 'Biz Corp')
        ..updateField('bizNumber', '123-45-67890')
        ..updateField('representativeName', 'John Doe')
        ..updateField('contactPhone', '010-1234-5678')
        ..updateField('contactEmail', 'biz@example.com')
        ..updateField('bankName', 'Kookmin')
        ..updateField('accountNumber', '123456789')
        ..updateField('accountHolder', 'John Doe');

      // Still false because bizRegistrationPath and bankbookPath are null
      expect(notifier.validateAll(), isFalse);
    });
  });
}
