// LocationGuidePageBuilder — location_guide_page 전용 fluent API.
//
// LocationGuidePage 는 정적 안내 화면이므로 provider 의존 없이 렌더 가능.
// loading 모드에서도 기본 레이아웃(AppBar 포함)을 유지하고 스피너만 오버레이한다.

import 'dart:async';

import 'package:app_partner/src/features/home/guide/location_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

class LocationGuidePageBuilder extends MdsScreenBuilder<LocationGuidePage> {
  LocationGuidePageBuilder() : super(page: const LocationGuidePage());

  bool _isLoading = false;
  Brightness _brightness = Brightness.light;

  /// 로딩 상태.
  LocationGuidePageBuilder loading() {
    _isLoading = true;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  /// 다크 모드.
  LocationGuidePageBuilder dark() {
    _brightness = Brightness.dark;
    // ignore: avoid_returning_this, fluent builder — callers chain methods
    return this;
  }

  @override
  Widget build() {
    final home = _isLoading
        ? const Stack(
            children: [
              LocationGuidePage(),
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: MinglitCircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          )
        : const LocationGuidePage();

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
