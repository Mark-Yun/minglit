// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_refresh_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DashboardRefresh)
const dashboardRefreshProvider = DashboardRefreshProvider._();

final class DashboardRefreshProvider
    extends $NotifierProvider<DashboardRefresh, int> {
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

String _$dashboardRefreshHash() => r'dashboard_refresh_notifier_v1';

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
