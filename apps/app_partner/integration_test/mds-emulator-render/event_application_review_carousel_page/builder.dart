import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventApplicationReviewCarouselPageRenderPage extends StatelessWidget {
  const _EventApplicationReviewCarouselPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_application_review_carousel_page'),
      ),
    );
  }
}

class EventApplicationReviewCarouselPageBuilder
    extends MdsScreenBuilder<_EventApplicationReviewCarouselPageRenderPage> {
  EventApplicationReviewCarouselPageBuilder()
    : super(page: const _EventApplicationReviewCarouselPageRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
