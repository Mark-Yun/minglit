import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _TicketCreatePageRenderPage extends StatelessWidget {
  const _TicketCreatePageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ticket_create_page'),
      ),
    );
  }
}

class TicketCreatePageBuilder
    extends MdsScreenBuilder<_TicketCreatePageRenderPage> {
  TicketCreatePageBuilder() : super(page: const _TicketCreatePageRenderPage());

  TicketCreatePageBuilder defaultState() {
    return this;
  }

  TicketCreatePageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
