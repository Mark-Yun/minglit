// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current environment domains.
/// Override this provider in `dev_main.dart` to switch environments.

@ProviderFor(minglitDomains)
const minglitDomainsProvider = MinglitDomainsProvider._();

/// Holds the current environment domains.
/// Override this provider in `dev_main.dart` to switch environments.

final class MinglitDomainsProvider
    extends $FunctionalProvider<MinglitDomains, MinglitDomains, MinglitDomains>
    with $Provider<MinglitDomains> {
  /// Holds the current environment domains.
  /// Override this provider in `dev_main.dart` to switch environments.
  const MinglitDomainsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minglitDomainsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minglitDomainsHash();

  @$internal
  @override
  $ProviderElement<MinglitDomains> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MinglitDomains create(Ref ref) {
    return minglitDomains(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MinglitDomains value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MinglitDomains>(value),
    );
  }
}

String _$minglitDomainsHash() => r'140ecde1b813e1cf271b78a30dd0b0804fba8431';

/// Computes the final URLs based on [minglitDomainsProvider].

@ProviderFor(minglitUrlConfig)
const minglitUrlConfigProvider = MinglitUrlConfigProvider._();

/// Computes the final URLs based on [minglitDomainsProvider].

final class MinglitUrlConfigProvider
    extends
        $FunctionalProvider<
          MinglitUrlConfig,
          MinglitUrlConfig,
          MinglitUrlConfig
        >
    with $Provider<MinglitUrlConfig> {
  /// Computes the final URLs based on [minglitDomainsProvider].
  const MinglitUrlConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'minglitUrlConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$minglitUrlConfigHash();

  @$internal
  @override
  $ProviderElement<MinglitUrlConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MinglitUrlConfig create(Ref ref) {
    return minglitUrlConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MinglitUrlConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MinglitUrlConfig>(value),
    );
  }
}

String _$minglitUrlConfigHash() => r'80485a9eefd1b14362e39d8b8d1f44c9f3e5c261';
