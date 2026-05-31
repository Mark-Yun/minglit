import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _PartnerEventDetailPageRenderPage extends StatelessWidget {
  const _PartnerEventDetailPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('partner_event_detail_page'),
      ),
    );
  }
}

class PartnerEventDetailPageBuilder
    extends MdsScreenBuilder<_PartnerEventDetailPageRenderPage> {
  PartnerEventDetailPageBuilder()
    : super(page: const _PartnerEventDetailPageRenderPage());

  void defaultState() {}

  void dark() => useDarkTheme();
}
