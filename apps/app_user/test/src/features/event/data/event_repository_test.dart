import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  test('EventRepository is available via provider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repository = container.read(eventRepositoryProvider);

    expect(repository, isA<EventRepository>());
  });
}
