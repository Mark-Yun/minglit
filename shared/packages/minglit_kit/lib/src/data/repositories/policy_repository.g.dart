// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(policyRepository)
const policyRepositoryProvider = PolicyRepositoryProvider._();

final class PolicyRepositoryProvider extends $FunctionalProvider<
    PolicyRepository,
    PolicyRepository,
    PolicyRepository> with $Provider<PolicyRepository> {
  const PolicyRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'policyRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$policyRepositoryHash();

  @$internal
  @override
  $ProviderElement<PolicyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PolicyRepository create(Ref ref) {
    return policyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PolicyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PolicyRepository>(value),
    );
  }
}

String _$policyRepositoryHash() => r'6388dec0fa0bfc9c4618ddac0d2b04310187cd70';
