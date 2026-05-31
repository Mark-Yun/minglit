import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventMatchingScreenRenderPage extends StatelessWidget {
  const _EventMatchingScreenRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_matching_screen'),
      ),
    );
  }
}

class EventMatchingScreenBuilder
    extends MdsScreenBuilder<_EventMatchingScreenRenderPage> {
  EventMatchingScreenBuilder()
    : super(page: const _EventMatchingScreenRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
