import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a [ProviderContainer] for testing with auto-dispose on teardown.
ProviderContainer createContainer({
  ProviderContainer? parent,
  List<dynamic> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides.cast(),
    observers: observers,
  );
  addTearDown(container.dispose);
  return container;
}
