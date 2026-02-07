// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iamport_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [IamportRepository] instance.

@ProviderFor(iamportRepository)
const iamportRepositoryProvider = IamportRepositoryProvider._();

/// Provides the [IamportRepository] instance.

final class IamportRepositoryProvider
    extends
        $FunctionalProvider<
          IamportRepository,
          IamportRepository,
          IamportRepository
        >
    with $Provider<IamportRepository> {
  /// Provides the [IamportRepository] instance.
  const IamportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iamportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iamportRepositoryHash();

  @$internal
  @override
  $ProviderElement<IamportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IamportRepository create(Ref ref) {
    return iamportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IamportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IamportRepository>(value),
    );
  }
}

String _$iamportRepositoryHash() => r'b6c5e9f7aeeb466d0dd7c2d23090dc236c98cdb9';
