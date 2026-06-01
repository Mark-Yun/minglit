import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _PartnerGuideRenderPage extends StatelessWidget {
  const _PartnerGuideRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('partner_guide'),
      ),
    );
  }
}

class PartnerGuideBuilder extends MdsScreenBuilder<_PartnerGuideRenderPage> {
  PartnerGuideBuilder() : super(page: const _PartnerGuideRenderPage());

  PartnerGuideBuilder defaultState() {
    return this;
  }

  PartnerGuideBuilder dark() {
    useDarkTheme();
    return this;
  }
}
