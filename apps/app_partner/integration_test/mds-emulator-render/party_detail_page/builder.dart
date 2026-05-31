import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _PartyDetailPageRenderPage extends StatelessWidget {
  const _PartyDetailPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('party_detail_page'),
      ),
    );
  }
}

class PartyDetailPageBuilder
    extends MdsScreenBuilder<_PartyDetailPageRenderPage> {
  PartyDetailPageBuilder() : super(page: const _PartyDetailPageRenderPage());

  PartyDetailPageBuilder defaultState() {
    return this;
  }

  PartyDetailPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
