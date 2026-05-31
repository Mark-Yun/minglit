import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventApplicationReviewConfirmPageRenderPage extends StatelessWidget {
  const _EventApplicationReviewConfirmPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_application_review_confirm_page'),
      ),
    );
  }
}

class EventApplicationReviewConfirmPageBuilder
    extends MdsScreenBuilder<_EventApplicationReviewConfirmPageRenderPage> {
  EventApplicationReviewConfirmPageBuilder()
    : super(page: const _EventApplicationReviewConfirmPageRenderPage());

  EventApplicationReviewConfirmPageBuilder defaultState() {
    return this;
  }

  EventApplicationReviewConfirmPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
