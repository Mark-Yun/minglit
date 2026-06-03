import 'package:app_partner/src/features/home/guide/partner_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class PartnerGuideBuilder extends MdsScreenBuilder<PartnerGuidePage> {
  PartnerGuideBuilder() : super(page: const PartnerGuidePage());

  bool _showTopicSheet = false;
  Brightness _brightness = Brightness.light;

  PartnerGuideBuilder defaultState() {
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  PartnerGuideBuilder withTopicSheet() {
    _showTopicSheet = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  PartnerGuideBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final home = _showTopicSheet
        ? const PartnerGuidePage(initialTopicSlug: 'dashboard-overview')
        : const PartnerGuidePage();

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: home,
      ),
    );
  }
}
