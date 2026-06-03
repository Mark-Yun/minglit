// MorePageBuilder — more_page 전용 fluent API.
//
// MorePage 는 currentPartnerInfoProvider / currentMemberPermissionsProvider
// / moreCoordinatorProvider / authControllerProvider 를 사용한다.
// MDS render에서는 네비게이션/인증 액션을 no-op으로 고정하고,
// 권한/프로필 state만 바꿔 2개 spec state를 재현한다.

import 'dart:async';

import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../_engine/builder.dart';

class _NoOpMoreCoordinator implements MoreCoordinator {
  @override
  void goToHome() {}

  @override
  void pushAccountDeletion() {}

  @override
  void pushAccountManagement() {}

  @override
  void pushBankAccountManagement() {}

  @override
  void pushMemberList(String partnerId) {}

  @override
  void pushNotificationSettings() {}

  @override
  void pushPartnerGuide() {}

  @override
  void pushPartyList() {}

  @override
  void pushVerificationManage() {}
}

class _NoOpAuthController extends AuthController {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> signOut() async {}
}

class MorePageBuilder extends MdsScreenBuilder<MorePage> {
  MorePageBuilder() : super(page: const MorePage());

  Partner? _partner = const Partner(
    id: 'mock-partner-1',
    name: '밍글릿 파트너',
    contactEmail: 'partner@example.com',
  );
  List<String> _permissions = const ['SETTLEMENT_EDIT'];
  bool _isPartnerLoading = false;
  bool _isPartnerError = false;

  /// Baseline: 정산 권한이 있는 전권 파트너.
  MorePageBuilder defaultState() {
    _partner = const Partner(
      id: 'mock-partner-1',
      name: '밍글릿 파트너',
      contactEmail: 'partner@example.com',
    );
    _permissions = const ['SETTLEMENT_EDIT'];
    _isPartnerLoading = false;
    _isPartnerError = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 제한 권한: 정산 권한이 없는 멤버.
  MorePageBuilder limitedPermissionsState() {
    _partner = const Partner(
      id: 'mock-partner-1',
      name: '밍글릿 파트너',
      contactEmail: 'staff@example.com',
    );
    _permissions = const [];
    _isPartnerLoading = false;
    _isPartnerError = false;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final partner = _partner;
    final permissions = _permissions;
    final isPartnerLoading = _isPartnerLoading;
    final isPartnerError = _isPartnerError;

    PackageInfo.setMockInitialValues(
      appName: 'Minglit Partner',
      packageName: 'com.minglit.partner',
      version: '26.04.1852-dev',
      buildNumber: '1',
      buildSignature: '',
    );

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        moreCoordinatorProvider.overrideWithValue(_NoOpMoreCoordinator()),
        authControllerProvider.overrideWith(_NoOpAuthController.new),
        minglitUrlConfigProvider.overrideWithValue(
          const MinglitUrlConfig(MinglitDomains.production()),
        ),
        currentPartnerInfoProvider.overrideWith((ref) async {
          if (isPartnerLoading) {
            await Future<void>.delayed(const Duration(days: 1));
          }
          if (isPartnerError) {
            throw Exception('정보를 불러올 수 없습니다');
          }
          return partner;
        }),
        currentMemberPermissionsProvider.overrideWith(
          (ref) async => permissions,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
        home: const MorePage(),
      ),
    );
  }
}
