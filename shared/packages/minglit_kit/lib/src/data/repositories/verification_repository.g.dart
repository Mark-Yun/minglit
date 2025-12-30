// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for VerificationRepository.

@ProviderFor(verificationRepository)
const verificationRepositoryProvider = VerificationRepositoryProvider._();

/// Provider for VerificationRepository.

final class VerificationRepositoryProvider
    extends
        $FunctionalProvider<
          VerificationRepository,
          VerificationRepository,
          VerificationRepository
        >
    with $Provider<VerificationRepository> {
  /// Provider for VerificationRepository.
  const VerificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<VerificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VerificationRepository create(Ref ref) {
    return verificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerificationRepository>(value),
    );
  }
}

String _$verificationRepositoryHash() =>
    r'7565991339f4129a3120544fa7c5468fd021b418';
