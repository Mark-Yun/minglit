// PartyListPageBuilder - party_list_page 전용 fluent API.
//
// PartyListPage 는 partyListProvider + partyListCoordinatorProvider 를 사용한다.
// MDS render에서는 provider/coordinator를 deterministic mock으로 고정해
// Default / Empty / Loading / Error / Help(시트 자동 오픈) 상태를 재현한다.

import 'dart:async';

import 'package:app_partner/src/features/party/list/party_help_sections.dart';
import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/party_list_page.dart';
import 'package:app_partner/src/features/party/list/party_with_stats.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

enum _PartyListScenario { defaultState, empty, loading, error, help }

class _NoOpPartyListCoordinator implements PartyListCoordinator {
  @override
  void goToCreate() {}

  @override
  void goToCreateEvent(String partyId) {}

  @override
  void goToDetail(String partyId) {}

  @override
  void goToEventDetail(String partyId, String eventId) {}
}

class _AutoOpenHelpSheet extends StatefulWidget {
  const _AutoOpenHelpSheet({required this.child});

  final Widget child;

  @override
  State<_AutoOpenHelpSheet> createState() => _AutoOpenHelpSheetState();
}

class _AutoOpenHelpSheetState extends State<_AutoOpenHelpSheet> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showMinglitHelpSheet(
          context: context,
          title: '파티 관리 가이드',
          sections: kPartyHelpSections,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

final _base = DateTime(2026, 5, 28, 18);

Partner _mockPartner() => const Partner(
  id: 'mock-partner-1',
  name: '밍글릿 강남 라운지',
);

Location _mockLocation() => Location(
  id: 'mock-location-1',
  partnerId: 'mock-partner-1',
  name: '밍글릿 강남홀',
  address: '서울 강남구 테헤란로 123',
  createdAt: _base,
  updatedAt: _base,
);

Party _mockParty() => Party(
  id: 'mock-party-1',
  partnerId: 'mock-partner-1',
  title: '금요일 소셜 나이트',
  createdAt: _base,
  updatedAt: _base,
  location: _mockLocation(),
  partner: _mockPartner(),
  tags: const [
    Tag(id: 'tag-1', name: '#맛집'),
    Tag(id: 'tag-2', name: '#와인'),
  ],
);

Event _mockNextEvent() => Event(
  id: 'mock-event-1',
  partyId: 'mock-party-1',
  title: '강남 밍글 파티',
  startTime: DateTime(2026, 6, 3, 19),
  endTime: DateTime(2026, 6, 3, 21),
  createdAt: _base,
  updatedAt: _base,
  currentParticipants: 16,
  maxParticipants: 24,
);

final _defaultEntries = <PartyWithStats>[
  PartyWithStats(
    party: _mockParty(),
    completedCount: 7,
    upcomingCount: 2,
    nextEvent: _mockNextEvent(),
  ),
];

class PartyListPageBuilder extends MdsScreenBuilder<Widget> {
  PartyListPageBuilder() : super(page: const PartyListPage());

  _PartyListScenario _scenario = _PartyListScenario.defaultState;
  Brightness _brightness = Brightness.light;

  PartyListPageBuilder defaultState() {
    _scenario = _PartyListScenario.defaultState;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartyListPageBuilder emptyState() {
    _scenario = _PartyListScenario.empty;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartyListPageBuilder loadingState() {
    _scenario = _PartyListScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartyListPageBuilder errorState() {
    _scenario = _PartyListScenario.error;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartyListPageBuilder helpState() {
    _scenario = _PartyListScenario.help;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartyListPageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;
    final brightness = _brightness;
    final coordinator = _NoOpPartyListCoordinator();

    final Widget home = scenario == _PartyListScenario.help
        ? const _AutoOpenHelpSheet(child: PartyListPage())
        : const PartyListPage();

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        partyListCoordinatorProvider.overrideWithValue(coordinator),
        partyListProvider.overrideWith((_) async {
          switch (scenario) {
            case _PartyListScenario.defaultState:
            case _PartyListScenario.help:
              return _defaultEntries;
            case _PartyListScenario.empty:
              return const <PartyWithStats>[];
            case _PartyListScenario.loading:
              return Completer<List<PartyWithStats>>().future;
            case _PartyListScenario.error:
              throw Exception('render: forced party list error');
          }
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: home,
      ),
    );
  }
}
