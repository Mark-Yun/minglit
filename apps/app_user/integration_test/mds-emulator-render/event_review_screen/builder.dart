import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _EventReviewScreenRenderPage extends StatelessWidget {
  const _EventReviewScreenRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('event_review_screen'),
      ),
    );
  }
}

class EventReviewScreenBuilder
    extends MdsScreenBuilder<_EventReviewScreenRenderPage> {
  EventReviewScreenBuilder()
    : super(page: const _EventReviewScreenRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
