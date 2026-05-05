// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_refresh_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared refresh signal for the partner dashboard.
/// Features that cause dashboard-relevant state changes (e.g. event creation)
/// call `DashboardRefreshNotifier.bump` instead of directly invalidating
/// `PartnerDashboardController`, avoiding cross-feature coupling.

@ProviderFor(DashboardRefresh)
const dashboardRefreshProvider = DashboardRefreshProvider._();

/// Shared refresh signal for the partner dashboard.
/// Features that cause dashboard-relevant state changes (e.g. event creation)
/// call `DashboardRefreshNotifier.bump` instead of directly invalidating
/// `PartnerDashboardController`, avoiding cross-feature coupling.
final class DashboardRefreshProvider
    extends $NotifierProvider<DashboardRefresh, int> {
  /// Shared refresh signal for the partner dashboard.
  /// Features that cause dashboard-relevant state changes (e.g. event creation)
  /// call `DashboardRefreshNotifier.bump` instead of directly invalidating
  /// `PartnerDashboardController`, avoiding cross-feature coupling.
  const DashboardRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardRefreshProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardRefreshHash();

  @$internal
  @override
  DashboardRefresh create() => DashboardRefresh();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dashboardRefreshHash() => r'fbe15ef07023ffe1b98764e7ab0dc70c1013ffec';

/// Shared refresh signal for the partner dashboard.
/// Features that cause dashboard-relevant state changes (e.g. event creation)
/// call `DashboardRefreshNotifier.bump` instead of directly invalidating
/// `PartnerDashboardController`, avoiding cross-feature coupling.

abstract class _$DashboardRefresh extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
