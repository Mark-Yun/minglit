import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventResultsScreenRenderPage extends StatelessWidget {
  const _EventResultsScreenRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_results_screen'),
      ),
    );
  }
}

class EventResultsScreenBuilder
    extends MdsScreenBuilder<_EventResultsScreenRenderPage> {
  EventResultsScreenBuilder()
    : super(page: const _EventResultsScreenRenderPage());

  EventResultsScreenBuilder defaultState() {
    return this;
  }

  EventResultsScreenBuilder dark() {
    useDarkTheme();
    return this;
  }
}
