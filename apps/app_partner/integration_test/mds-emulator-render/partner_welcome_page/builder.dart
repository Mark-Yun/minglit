import 'dart:async';

import 'package:app_partner/src/features/onboarding/partner_welcome_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class PartnerWelcomePageBuilder extends MdsScreenBuilder<PartnerWelcomePage> {
  PartnerWelcomePageBuilder() : super(page: const PartnerWelcomePage());

  Brightness _brightness = Brightness.light;

  PartnerWelcomePageBuilder defaultState() {
    _brightness = Brightness.light;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerWelcomePageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const PartnerWelcomePage(),
      ),
    );
  }
}
