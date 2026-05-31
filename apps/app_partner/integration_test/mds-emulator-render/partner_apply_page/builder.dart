import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _PartnerApplyPageRenderPage extends StatelessWidget {
  const _PartnerApplyPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('partner_apply_page'),
      ),
    );
  }
}

class PartnerApplyPageBuilder
    extends MdsScreenBuilder<_PartnerApplyPageRenderPage> {
  PartnerApplyPageBuilder() : super(page: const _PartnerApplyPageRenderPage());

  PartnerApplyPageBuilder defaultState() {
    return this;
  }

  PartnerApplyPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
