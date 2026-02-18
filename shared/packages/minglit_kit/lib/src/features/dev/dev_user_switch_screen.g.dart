// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev_user_switch_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches test user profiles for the dev user switcher.

@ProviderFor(devUserProfiles)
const devUserProfilesProvider = DevUserProfilesProvider._();

/// Fetches test user profiles for the dev user switcher.

final class DevUserProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// Fetches test user profiles for the dev user switcher.
  const DevUserProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devUserProfilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devUserProfilesHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return devUserProfiles(ref);
  }
}

String _$devUserProfilesHash() => r'a102a91dc1c4c5265aa2bd7e8e95f9b6e9c1ea58';
