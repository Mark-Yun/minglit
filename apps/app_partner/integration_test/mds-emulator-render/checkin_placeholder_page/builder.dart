// CheckinPlaceholderPageBuilder — checkin_placeholder_page 전용 fluent API.
//
// CheckinPlaceholderPage 는 currentPartnerInfoProvider (Partner?) 와
// todayEventsProvider(partnerId) (List<Event>) 를 watch 한다.
//
// build() 직접 override 로 currentPartnerInfoProvider 중복 override 방지
// (_commonRootOverrides() 내 currentUserProvider 와 충돌 없이 독립 구성).

import 'package:app_partner/src/features/checkin/checkin_placeholder_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/data.dart';

class CheckinPlaceholderPageBuilder
    extends MdsScreenBuilder<CheckinPlaceholderPage> {
  CheckinPlaceholderPageBuilder() : super(page: const CheckinPlaceholderPage());

  Partner? _partner;
  bool _isLoading = false;
  bool _partnerLoadError = false;
  List<Event> _events = [];
  Brightness _brightness = Brightness.light;

  /// loading 상태 — partner 정보 로딩 중.
  CheckinPlaceholderPageBuilder loading() {
    _isLoading = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// error 상태 — partner 정보 로드 실패.
  CheckinPlaceholderPageBuilder error() {
    _partnerLoadError = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// partner 정보 있음 + 오늘 이벤트 0개.
  CheckinPlaceholderPageBuilder withNoEvents() {
    _partner = mockPartner();
    _events = [];
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// partner 정보 있음 + 오늘 이벤트 2+개 (선택 목록 표시).
  CheckinPlaceholderPageBuilder withMultipleEvents(int count) {
    _partner = mockPartner();
    _events = mockEvents(count: count);
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 다크 모드.
  CheckinPlaceholderPageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final partner = _partner;
    final isLoading = _isLoading;
    final hasError = _partnerLoadError;
    final events = _events;

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        currentPartnerInfoProvider.overrideWith((ref) async {
          if (isLoading) {
            await Future<void>.delayed(const Duration(days: 1));
          }
          if (hasError) {
            throw Exception('파트너 정보를 불러올 수 없습니다');
          }
          return partner;
        }),
        if (partner != null)
          todayEventsProvider.overrideWith(
            (ref, partnerId) async => events,
          ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const CheckinPlaceholderPage(),
      ),
    );
  }
}
