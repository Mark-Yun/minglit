import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventCheckInScreenRenderPage extends StatelessWidget {
  const _EventCheckInScreenRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_check_in_screen'),
      ),
    );
  }
}

class EventCheckInScreenBuilder
    extends MdsScreenBuilder<_EventCheckInScreenRenderPage> {
  EventCheckInScreenBuilder()
    : super(page: const _EventCheckInScreenRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
