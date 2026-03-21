// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current signed-in user's profile, if available.

@ProviderFor(currentUserProfile)
const currentUserProfileProvider = CurrentUserProfileProvider._();

/// Provides the current signed-in user's profile, if available.

final class CurrentUserProfileProvider extends $FunctionalProvider<
        AsyncValue<UserProfile?>, UserProfile?, FutureOr<UserProfile?>>
    with $FutureModifier<UserProfile?>, $FutureProvider<UserProfile?> {
  /// Provides the current signed-in user's profile, if available.
  const CurrentUserProfileProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserProfileProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserProfileHash();

  @$internal
  @override
  $FutureProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserProfile?> create(Ref ref) {
    return currentUserProfile(ref);
  }
}

String _$currentUserProfileHash() =>
    r'bc92d80a2a7056e4550ee728b394e66c05b470c3';
