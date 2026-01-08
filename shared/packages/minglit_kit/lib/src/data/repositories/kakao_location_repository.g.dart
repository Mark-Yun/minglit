// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kakao_location_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kakaoLocationRepository)
const kakaoLocationRepositoryProvider = KakaoLocationRepositoryProvider._();

final class KakaoLocationRepositoryProvider
    extends
        $FunctionalProvider<
          KakaoLocationRepository,
          KakaoLocationRepository,
          KakaoLocationRepository
        >
    with $Provider<KakaoLocationRepository> {
  const KakaoLocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kakaoLocationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kakaoLocationRepositoryHash();

  @$internal
  @override
  $ProviderElement<KakaoLocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KakaoLocationRepository create(Ref ref) {
    return kakaoLocationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KakaoLocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KakaoLocationRepository>(value),
    );
  }
}

String _$kakaoLocationRepositoryHash() =>
    r'55336abe5453f990ef6594c4d67a870784229c19';
