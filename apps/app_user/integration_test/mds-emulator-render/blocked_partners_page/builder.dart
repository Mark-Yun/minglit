// BlockedPartnersPageBuilder — blocked_partners_page 전용 fluent API.
//
// blockedPartnersProvider (FutureProvider.autoDispose) 를 직접 override 해
// loading / empty / with-partners 상태를 렌더링.
// BlockedPartnersPage 의 unblock 버튼은 상호작용이 필요하므로
// 렌더 catalog 에서는 초기 UI(목록 표시)만 캡처.

import 'dart:async';

import 'package:app_user/src/features/settings/blocked_partners_page.dart';

import '../_engine/builder.dart';

/// mock partner 2건.
const List<Map<String, Object?>> _mockPartners = [
  {
    'id': 'partner-1',
    'name': '카페 밍릿',
    'profile_image_url': null,
  },
  {
    'id': 'partner-2',
    'name': '밍릿 하우스',
    'profile_image_url': null,
  },
];

class BlockedPartnersPageBuilder
    extends MdsScreenBuilder<BlockedPartnersPage> {
  BlockedPartnersPageBuilder() : super(page: const BlockedPartnersPage());

  /// 로딩 중 (future 미완료).
  BlockedPartnersPageBuilder loading() {
    addOverride(
      blockedPartnersProvider.overrideWith(
        (_) => Completer<List<Map<String, dynamic>>>().future,
      ),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 차단 목록 없음 (빈 상태).
  BlockedPartnersPageBuilder empty() {
    addOverride(blockedPartnersProvider.overrideWith((_) async => []));
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 차단된 파트너 2건 표시.
  BlockedPartnersPageBuilder withPartners() {
    addOverride(
      blockedPartnersProvider.overrideWith((_) async => _mockPartners),
    );
    // ignore: avoid_returning_this, fluent builder
    return this;
  }

  /// 다크 모드 토글.
  BlockedPartnersPageBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder
    return this;
  }
}
