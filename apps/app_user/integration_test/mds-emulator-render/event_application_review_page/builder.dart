import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventApplicationReviewPageRenderPage extends StatelessWidget {
  const _EventApplicationReviewPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_application_review_page'),
      ),
    );
  }
}

class EventApplicationReviewPageBuilder
    extends MdsScreenBuilder<_EventApplicationReviewPageRenderPage> {
  EventApplicationReviewPageBuilder()
    : super(page: const _EventApplicationReviewPageRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
