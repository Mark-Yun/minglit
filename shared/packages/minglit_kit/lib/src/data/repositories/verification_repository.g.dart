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

@ProviderFor(verificationsByIds)
const verificationsByIdsProvider = VerificationsByIdsFamily._();

final class VerificationsByIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Verification>>,
          List<Verification>,
          FutureOr<List<Verification>>
        >
    with
        $FutureModifier<List<Verification>>,
        $FutureProvider<List<Verification>> {
  const VerificationsByIdsProvider._({
    required VerificationsByIdsFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'verificationsByIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$verificationsByIdsHash();

  @override
  String toString() {
    return r'verificationsByIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Verification>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Verification>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return verificationsByIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VerificationsByIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$verificationsByIdsHash() =>
    r'56316be7791e011cb69b886a57a955344090d2d7';

final class VerificationsByIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Verification>>, List<String>> {
  const VerificationsByIdsFamily._()
    : super(
        retry: null,
        name: r'verificationsByIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VerificationsByIdsProvider call(List<String> ids) =>
      VerificationsByIdsProvider._(argument: ids, from: this);

  @override
  String toString() => r'verificationsByIdsProvider';
}
