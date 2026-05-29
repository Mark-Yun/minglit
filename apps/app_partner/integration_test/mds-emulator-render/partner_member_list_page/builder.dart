import 'dart:async';

import 'package:app_partner/src/features/member/partner_member_list_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

const _mockPartnerId = 'mock-partner-1';

enum _PartnerMemberListScenario { defaultState, empty, loading, error, invite }

const _defaultMembers = <Map<String, dynamic>>[
  {
    'user_id': 'owner-1',
    'role': 'owner',
    'user': {'name': '박민호'},
  },
  {
    'user_id': 'manager-1',
    'role': 'manager',
    'user': {'name': '김서연'},
  },
  {
    'user_id': 'staff-1',
    'role': 'staff',
    'user': {'name': '이도윤'},
  },
];

class _AutoShowInviteMessage extends StatefulWidget {
  const _AutoShowInviteMessage({required this.child});

  final Widget child;

  @override
  State<_AutoShowInviteMessage> createState() => _AutoShowInviteMessageState();
}

class _AutoShowInviteMessageState extends State<_AutoShowInviteMessage> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.showMinglitInfo('준비 중입니다.');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PartnerMemberListPageBuilder
    extends MdsScreenBuilder<PartnerMemberListPage> {
  PartnerMemberListPageBuilder()
    : super(page: const PartnerMemberListPage(partnerId: _mockPartnerId));

  _PartnerMemberListScenario _scenario =
      _PartnerMemberListScenario.defaultState;

  PartnerMemberListPageBuilder defaultState() {
    _scenario = _PartnerMemberListScenario.defaultState;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberListPageBuilder empty() {
    _scenario = _PartnerMemberListScenario.empty;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberListPageBuilder loading() {
    _scenario = _PartnerMemberListScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberListPageBuilder error() {
    _scenario = _PartnerMemberListScenario.error;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberListPageBuilder inviteSnackbar() {
    _scenario = _PartnerMemberListScenario.invite;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;
    final Widget home = scenario == _PartnerMemberListScenario.invite
        ? const _AutoShowInviteMessage(
            child: PartnerMemberListPage(partnerId: _mockPartnerId),
          )
        : const PartnerMemberListPage(partnerId: _mockPartnerId);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        partnerMembersProvider(
          partnerId: _mockPartnerId,
        ).overrideWith((ref) async {
          switch (scenario) {
            case _PartnerMemberListScenario.defaultState:
            case _PartnerMemberListScenario.invite:
              return _defaultMembers;
            case _PartnerMemberListScenario.empty:
              return const <Map<String, dynamic>>[];
            case _PartnerMemberListScenario.loading:
              return Completer<List<Map<String, dynamic>>>().future;
            case _PartnerMemberListScenario.error:
              throw Exception('render: forced partner member list error');
          }
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: MinglitTheme.materialTheme,
        home: home,
      ),
    );
  }
}
