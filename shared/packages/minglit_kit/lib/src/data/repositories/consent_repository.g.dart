// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [ConsentRepository].

@ProviderFor(consentRepository)
const consentRepositoryProvider = ConsentRepositoryProvider._();

/// Provides the [ConsentRepository].

final class ConsentRepositoryProvider
    extends
        $FunctionalProvider<
          ConsentRepository,
          ConsentRepository,
          ConsentRepository
        >
    with $Provider<ConsentRepository> {
  /// Provides the [ConsentRepository].
  const ConsentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConsentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConsentRepository create(Ref ref) {
    return consentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsentRepository>(value),
    );
  }
}

String _$consentRepositoryHash() => r'3d782945df0b090959d095aaf9cb0b6638bec125';
