import 'dart:async';

import 'package:app_partner/src/features/member/partner_member_permission_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

const _mockPartnerId = 'mock-partner-1';
const _mockTargetUserId = 'mock-user-1';

enum _PartnerMemberPermissionScenario {
  defaultState,
  ownerRole,
  notFound,
  loading,
  error,
}

const _managerMember = <String, dynamic>{
  'user_id': _mockTargetUserId,
  'role': 'manager',
  'permissions': <String>[
    'PARTNER_EDIT',
    'SETTLEMENT_VIEW',
    'PARTY_MANAGE',
  ],
  'user': <String, dynamic>{'name': '김서연', 'email': 'manager@minglit.com'},
};

const _ownerMember = <String, dynamic>{
  'user_id': _mockTargetUserId,
  'role': 'owner',
  'permissions': <String>[
    'PARTNER_EDIT',
    'SETTLEMENT_VIEW',
    'SETTLEMENT_EDIT',
    'MEMBER_MANAGE',
    'PARTY_MANAGE',
    'VERIFY_LIST_VIEW',
    'USER_DATA_VIEW',
    'VERIFY_REVIEW',
    'COMMENT_MANAGE',
  ],
  'user': <String, dynamic>{'name': '박민호', 'email': 'owner@minglit.com'},
};

class PartnerMemberPermissionPageBuilder
    extends MdsScreenBuilder<PartnerMemberPermissionPage> {
  PartnerMemberPermissionPageBuilder()
    : super(
        page: const PartnerMemberPermissionPage(
          partnerId: _mockPartnerId,
          targetUserId: _mockTargetUserId,
        ),
      );

  _PartnerMemberPermissionScenario _scenario =
      _PartnerMemberPermissionScenario.defaultState;

  PartnerMemberPermissionPageBuilder defaultState() {
    _scenario = _PartnerMemberPermissionScenario.defaultState;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberPermissionPageBuilder ownerRole() {
    _scenario = _PartnerMemberPermissionScenario.ownerRole;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberPermissionPageBuilder notFound() {
    _scenario = _PartnerMemberPermissionScenario.notFound;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberPermissionPageBuilder loading() {
    _scenario = _PartnerMemberPermissionScenario.loading;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  PartnerMemberPermissionPageBuilder error() {
    _scenario = _PartnerMemberPermissionScenario.error;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenario = _scenario;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        partnerMemberProvider(
          partnerId: _mockPartnerId,
          targetUserId: _mockTargetUserId,
        ).overrideWith((ref) async {
          switch (scenario) {
            case _PartnerMemberPermissionScenario.defaultState:
              return _managerMember;
            case _PartnerMemberPermissionScenario.ownerRole:
              return _ownerMember;
            case _PartnerMemberPermissionScenario.notFound:
              return null;
            case _PartnerMemberPermissionScenario.loading:
              return Completer<Map<String, dynamic>?>().future;
            case _PartnerMemberPermissionScenario.error:
              throw Exception('render: forced partner member permission error');
          }
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        theme: MinglitTheme.materialTheme,
        home: const PartnerMemberPermissionPage(
          partnerId: _mockPartnerId,
          targetUserId: _mockTargetUserId,
        ),
      ),
    );
  }
}
