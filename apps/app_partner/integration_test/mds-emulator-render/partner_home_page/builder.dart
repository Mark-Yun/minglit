import 'dart:async';

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class _LoadedDashboardController extends PartnerDashboardController {
  @override
  PartnerDashboardState build() {
    final now = DateTime(2026, 5, 29, 12);
    final event = Event(
      id: 'event-1',
      partyId: 'party-1',
      title: '강남 소셜 밍글',
      startTime: now.add(const Duration(hours: 5)),
      endTime: now.add(const Duration(hours: 8)),
      createdAt: now,
      updatedAt: now,
      currentParticipants: 16,
      maxParticipants: 24,
    );
    final party = Party(
      id: 'party-1',
      partnerId: 'partner-1',
      title: '금요일 네트워킹',
      createdAt: now,
      updatedAt: now,
    );

    return PartnerDashboardState(
      status: const AsyncValue.data(null),
      pendingReviewCount: 3,
      recruitingEvents: [event],
      activeParties: [party],
      totalPartyCount: 1,
      totalAttendees: 16,
      hasAnyEvents: true,
    );
  }
}

class _NoOpNotificationList extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => const [];
}

class _NoOpPartnerHomeCoordinator implements PartnerHomeCoordinator {
  @override
  void goToApplicationList() {}

  @override
  void goToCheckin() {}

  @override
  void goToSettlement() {}

  @override
  void pushApplicationList() {}

  @override
  void pushEventCreate(String partyId) {}

  @override
  void pushEventDetail({required String partyId, required String eventId}) {}

  @override
  void pushLocationGuide() {}

  @override
  void pushNotificationCenter() {}

  @override
  void pushPartyCreate() {}

  @override
  void pushPartyEdit(String partyId) {}
}

class PartnerHomePageBuilder extends MdsScreenBuilder<PartnerHomePage> {
  PartnerHomePageBuilder() : super(page: const PartnerHomePage());

  Brightness _brightness = Brightness.light;

  PartnerHomePageBuilder defaultState() {
    _brightness = Brightness.light;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerHomePageBuilder dark() {
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
        currentPartnerInfoProvider.overrideWith(
          (_) async => const Partner(id: 'partner-1', name: '밍글릿 강남 라운지'),
        ),
        partnerDashboardControllerProvider.overrideWith(
          _LoadedDashboardController.new,
        ),
        notificationListProvider.overrideWith(_NoOpNotificationList.new),
        partnerHomeCoordinatorProvider.overrideWith(
          (_) => _NoOpPartnerHomeCoordinator(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const PartnerHomePage(),
      ),
    );
  }
}
