import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventDetailPageRenderPage extends StatelessWidget {
  const _EventDetailPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_detail_page'),
      ),
    );
  }
}

class EventDetailPageBuilder
    extends MdsScreenBuilder<_EventDetailPageRenderPage> {
  EventDetailPageBuilder() : super(page: const _EventDetailPageRenderPage());

  EventDetailPageBuilder defaultState() {
    return this;
  }

  EventDetailPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
