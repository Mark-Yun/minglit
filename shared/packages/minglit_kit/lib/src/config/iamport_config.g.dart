// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iamport_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current [IamportConfig].

@ProviderFor(iamportConfig)
const iamportConfigProvider = IamportConfigProvider._();

/// Provides the current [IamportConfig].

final class IamportConfigProvider
    extends $FunctionalProvider<IamportConfig, IamportConfig, IamportConfig>
    with $Provider<IamportConfig> {
  /// Provides the current [IamportConfig].
  const IamportConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iamportConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iamportConfigHash();

  @$internal
  @override
  $ProviderElement<IamportConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IamportConfig create(Ref ref) {
    return iamportConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IamportConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IamportConfig>(value),
    );
  }
}

String _$iamportConfigHash() => r'a8b2bfe7b59605aa1b8359a125faca7db4fe3ab2';
