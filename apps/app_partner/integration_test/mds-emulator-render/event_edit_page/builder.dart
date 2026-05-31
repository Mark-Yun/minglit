import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventEditPageRenderPage extends StatelessWidget {
  const _EventEditPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_edit_page'),
      ),
    );
  }
}

class EventEditPageBuilder extends MdsScreenBuilder<_EventEditPageRenderPage> {
  EventEditPageBuilder() : super(page: const _EventEditPageRenderPage());

  EventEditPageBuilder defaultState() {
    return this;
  }

  EventEditPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
