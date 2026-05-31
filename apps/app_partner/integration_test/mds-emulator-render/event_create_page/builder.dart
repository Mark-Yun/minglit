import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventCreatePageRenderPage extends StatelessWidget {
  const _EventCreatePageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_create_page'),
      ),
    );
  }
}

class EventCreatePageBuilder
    extends MdsScreenBuilder<_EventCreatePageRenderPage> {
  EventCreatePageBuilder() : super(page: const _EventCreatePageRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
