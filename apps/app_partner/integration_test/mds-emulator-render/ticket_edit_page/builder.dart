import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _TicketEditPageRenderPage extends StatelessWidget {
  const _TicketEditPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ticket_edit_page'),
      ),
    );
  }
}

class TicketEditPageBuilder
    extends MdsScreenBuilder<_TicketEditPageRenderPage> {
  TicketEditPageBuilder() : super(page: const _TicketEditPageRenderPage());

  TicketEditPageBuilder defaultState() {
    return this;
  }

  TicketEditPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
