import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../../../../utils/test_utils.dart';

void main() {
  ProviderContainer makeContainer() {
    return createContainer(overrides: []);
  }

  group('PartyCreateWizardController - initial state', () {
    test('starts at basicInfo step', () {
      final container = makeContainer();
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.currentStep, PartyCreateStep.basicInfo);
    });

    test('default values are set correctly', () {
      final container = makeContainer();
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.title, '');
      expect(state.minConfirmedCount, 5);
      expect(state.maxParticipants, 0);
      expect(state.visibility, 'public');
      expect(state.status, isA<AsyncData<void>>());
    });
  });

  group('PartyCreateWizardController - navigation', () {
    test('nextStep advances to next step', () {
      final container = makeContainer();
      container
          .read(partyCreateWizardControllerProvider.notifier)
          .nextStep();
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.currentStep, PartyCreateStep.location);
    });

    test('previousStep stays at basicInfo when already at first step', () {
      final container = makeContainer();
      container
          .read(partyCreateWizardControllerProvider.notifier)
          .previousStep();
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.currentStep, PartyCreateStep.basicInfo);
    });

    test('setStep jumps to specified step', () {
      final container = makeContainer();
      container
          .read(partyCreateWizardControllerProvider.notifier)
          .setStep(PartyCreateStep.tickets);
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.currentStep, PartyCreateStep.tickets);
    });

    test('nextStep from last step does not overflow', () {
      final container = makeContainer();
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.setStep(PartyCreateStep.review);
      notifier.nextStep();

      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.currentStep, PartyCreateStep.review);
    });
  });

  group('PartyCreateWizardController - field updates', () {
    test('updateTitle updates title', () {
      final container = makeContainer();
      container
          .read(partyCreateWizardControllerProvider.notifier)
          .updateTitle('My Party');
      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.title, 'My Party');
    });

    test('toggleContactMethod adds and removes method', () {
      final container = makeContainer();
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.toggleContactMethod('phone');
      expect(
        container
            .read(partyCreateWizardControllerProvider)
            .enabledContactMethods,
        contains('phone'),
      );

      notifier.toggleContactMethod('phone');
      expect(
        container
            .read(partyCreateWizardControllerProvider)
            .enabledContactMethods,
        isNot(contains('phone')),
      );
    });

    test('updateLocation sets selectedLocation', () {
      final container = makeContainer();
      final loc = Location(
        id: 'loc-1',
        partnerId: 'partner-1',
        name: 'Venue',
        address: '123 Main St',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      container
          .read(partyCreateWizardControllerProvider.notifier)
          .updateLocation(loc);

      final state = container.read(partyCreateWizardControllerProvider);
      expect(state.selectedLocation?.id, 'loc-1');
    });
  });

  group('PartyCreateWizardController - validation', () {
    test('validationErrors includes errors when state is empty', () {
      final container = makeContainer();
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);
      final errors = notifier.validationErrors;
      // Expect errors for: title, description, location, contact methods,
      // entry groups, tickets
      expect(errors.length, greaterThanOrEqualTo(4));
    });

    test('validationErrors is empty when all required fields are provided', () {
      final container = makeContainer();
      final notifier =
          container.read(partyCreateWizardControllerProvider.notifier);

      notifier.updateTitle('Great Party');
      notifier.updateDescription({
        'ops': [
          {'insert': 'Some description text\n'},
        ],
      });
      notifier.updateLocation(
        Location(
          id: 'loc-1',
          partnerId: 'partner-1',
          name: 'Venue',
          address: '123 Main St',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      );
      notifier.toggleContactMethod('phone');
      notifier.addEntryGroup(
        const EntryGroupTemplate(
          id: 'group-1',
          partyId: 'party-1',
          label: 'Male',
          gender: 'male',
        ),
      );
      notifier.addTicket(
        TicketTemplate(
          id: 'tpl-1',
          partyId: 'party-1',
          name: 'General',
          price: 10000,
          quantity: 20,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      );
      // Set min <= max to pass capacity check
      notifier.updateCapacity(min: 5);
      // maxParticipants defaults to 0, need to set it higher via tickets
      // The validation compares minConfirmedCount > maxParticipants.
      // Default maxParticipants=0, minConfirmedCount will be set to 5.
      // We need maxParticipants >= minConfirmedCount.
      // updateCapacity only updates min; set max via direct state inspection.
      // Since there is no updateMaxParticipants on wizard, set min to 0.
      notifier.updateCapacity(min: 0);

      final errors = notifier.validationErrors;
      expect(errors, isEmpty);
    });
  });
}
