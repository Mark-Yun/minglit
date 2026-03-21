// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for SocialRepository.

@ProviderFor(socialRepository)
const socialRepositoryProvider = SocialRepositoryProvider._();

/// Provider for SocialRepository.

final class SocialRepositoryProvider extends $FunctionalProvider<
    SocialRepository,
    SocialRepository,
    SocialRepository> with $Provider<SocialRepository> {
  /// Provider for SocialRepository.
  const SocialRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'socialRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$socialRepositoryHash();

  @$internal
  @override
  $ProviderElement<SocialRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SocialRepository create(Ref ref) {
    return socialRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialRepository>(value),
    );
  }
}

String _$socialRepositoryHash() => r'290cf44dcf40b6abff9b70add7e2b6d333c23786';
