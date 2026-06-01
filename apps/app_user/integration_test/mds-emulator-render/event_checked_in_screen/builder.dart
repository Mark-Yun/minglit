import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventCheckedInScreenRenderPage extends StatelessWidget {
  const _EventCheckedInScreenRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_checked_in_screen'),
      ),
    );
  }
}

class EventCheckedInScreenBuilder
    extends MdsScreenBuilder<_EventCheckedInScreenRenderPage> {
  EventCheckedInScreenBuilder()
    : super(page: const _EventCheckedInScreenRenderPage());

  EventCheckedInScreenBuilder defaultState() {
    return this;
  }

  EventCheckedInScreenBuilder dark() {
    useDarkTheme();
    return this;
  }
}
