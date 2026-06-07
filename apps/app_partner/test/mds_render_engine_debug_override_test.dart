import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/mds-emulator-render/_engine/builder.dart';
import '../integration_test/mds-emulator-render/_engine/catalog.dart';
import '../integration_test/mds-emulator-render/_engine/runner.dart';
import '../integration_test/mds-emulator-render/_engine/state.dart';

class _DebugPlatformBuilder extends MdsScreenBuilder<Widget> {
  _DebugPlatformBuilder() : super(page: const SizedBox.shrink());

  @override
  Widget build() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    return const MaterialApp(home: SizedBox.shrink());
  }
}

void main() {
  testWidgets('clears debug platform override before test invariant', (
    tester,
  ) async {
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    final catalog = MdsCatalog<_DebugPlatformBuilder>(
      screen: 'debug_platform',
      mdsSpec: 'test-only',
      builder: _DebugPlatformBuilder.new,
      states: [
        MdsState<_DebugPlatformBuilder>('state-default', (builder) => builder),
      ],
    );

    await MdsRenderEngine.pumpStateForTest(
      tester: tester,
      catalog: catalog,
      state: catalog.states.single,
    );

    expect(debugDefaultTargetPlatformOverride, isNull);
  });
}
