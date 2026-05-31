import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventApplicationWizardPageRenderPage extends StatelessWidget {
  const _EventApplicationWizardPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_application_wizard_page'),
      ),
    );
  }
}

class EventApplicationWizardPageBuilder
    extends MdsScreenBuilder<_EventApplicationWizardPageRenderPage> {
  EventApplicationWizardPageBuilder()
    : super(page: const _EventApplicationWizardPageRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
