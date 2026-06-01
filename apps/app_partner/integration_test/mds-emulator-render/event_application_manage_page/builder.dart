import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventApplicationManagePageRenderPage extends StatelessWidget {
  const _EventApplicationManagePageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_application_manage_page'),
      ),
    );
  }
}

class EventApplicationManagePageBuilder
    extends MdsScreenBuilder<_EventApplicationManagePageRenderPage> {
  EventApplicationManagePageBuilder()
    : super(page: const _EventApplicationManagePageRenderPage());

  EventApplicationManagePageBuilder defaultState() {
    return this;
  }

  EventApplicationManagePageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
