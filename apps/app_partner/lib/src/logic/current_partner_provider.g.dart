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

/// Returns the current user's permission list for the active partner.
/// Empty list when partner or auth state is unavailable.

@ProviderFor(currentMemberPermissions)
const currentMemberPermissionsProvider = CurrentMemberPermissionsProvider._();

/// Returns the current user's permission list for the active partner.
/// Empty list when partner or auth state is unavailable.

final class CurrentMemberPermissionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Returns the current user's permission list for the active partner.
  /// Empty list when partner or auth state is unavailable.
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
    r'15d6d6878e028482959535cd623025b01a10e59a';
