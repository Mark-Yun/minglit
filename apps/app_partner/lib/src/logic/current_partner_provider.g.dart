// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_partner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentPartnerInfo)
const currentPartnerInfoProvider = CurrentPartnerInfoProvider._();

final class CurrentPartnerInfoProvider
    extends
        $FunctionalProvider<AsyncValue<Partner?>, Partner?, FutureOr<Partner?>>
    with $FutureModifier<Partner?>, $FutureProvider<Partner?> {
  const CurrentPartnerInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPartnerInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPartnerInfoHash();

  @$internal
  @override
  $FutureProviderElement<Partner?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Partner?> create(Ref ref) {
    return currentPartnerInfo(ref);
  }
}

String _$currentPartnerInfoHash() =>
    r'c0296f7da2cb82e41e8b5b524d60f45e9808a3aa';

@ProviderFor(currentMemberPermissions)
const currentMemberPermissionsProvider = CurrentMemberPermissionsProvider._();

final class CurrentMemberPermissionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  const CurrentMemberPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMemberPermissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMemberPermissionsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return currentMemberPermissions(ref);
  }
}

String _$currentMemberPermissionsHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';
