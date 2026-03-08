import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a [ProviderContainer] for testing.
///
/// Use [overrides] to mock providers.
/// Use [observers] to spy on provider changes.
ProviderContainer createContainer({
  ProviderContainer? parent,
  List<dynamic> overrides =
      const [], // Use dynamic to bypass Override type issue
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides.cast(), // Implicit cast
    observers: observers,
  );

  // When the test ends, dispose the container.
  addTearDown(container.dispose);

  return container;
}
