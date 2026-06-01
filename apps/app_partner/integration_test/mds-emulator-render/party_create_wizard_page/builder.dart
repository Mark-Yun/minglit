import 'package:flutter/material.dart';

import '../_engine/builder.dart';

class _PartyCreateWizardPageRenderPage extends StatelessWidget {
  const _PartyCreateWizardPageRenderPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('party_create_wizard_page'),
      ),
    );
  }
}

class PartyCreateWizardPageBuilder
    extends MdsScreenBuilder<_PartyCreateWizardPageRenderPage> {
  PartyCreateWizardPageBuilder()
    : super(page: const _PartyCreateWizardPageRenderPage());

  PartyCreateWizardPageBuilder defaultState() {
    return this;
  }

  PartyCreateWizardPageBuilder dark() {
    useDarkTheme();
    return this;
  }
}
