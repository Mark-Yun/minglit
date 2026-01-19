import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import '../../utils/test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('S04-01: Partner Event Application List', () {
    late EventRepository eventRepo;

    setUpAll(() async {
      final container = await TestHelper.initialize();
      eventRepo = container.read(eventRepositoryProvider);
    });

    testWidgets('Should fetch event applications without Type Error', (
      tester,
    ) async {
      // 1. Fetch any event
      final events = await eventRepo.getEventsByType(
        type: EventFeedType.newArrivals,
      );
      if (events.isEmpty) {
        Log.w('No events found to test application list');
        return;
      }

      final targetEvent = events.first;
      Log.i('Testing with event: ${targetEvent.title} (${targetEvent.id})');

      try {
        final applications = await eventRepo.getApplicationsByEventId(
          targetEvent.id,
        );
        Log.i('Successfully fetched ${applications.length} applications');

        // Validation
        if (applications.isNotEmpty) {
          final firstApp = applications.first;
          // The bug is often that relations are Lists instead of Maps (single: true missing?)
          // Checking runtime type indirectly via model access
          expect(
            firstApp.user,
            isNotNull,
            reason: 'User relation should be loaded',
          );
        }
      } catch (e) {
        Log.e('Failed to fetch applications: $e');
        if (e is TypeError) {
          fail('TypeError detected! This confirms the bug.');
        }
        rethrow;
      }
    });
  });
}
