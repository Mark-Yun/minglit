// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages user consent state for the current user.
///
/// Loads active consents on build, provides methods to save
/// signup consents and toggle individual consents.

@ProviderFor(ConsentController)
const consentControllerProvider = ConsentControllerProvider._();

/// Manages user consent state for the current user.
///
/// Loads active consents on build, provides methods to save
/// signup consents and toggle individual consents.
final class ConsentControllerProvider
    extends $AsyncNotifierProvider<ConsentController, List<UserConsent>> {
  /// Manages user consent state for the current user.
  ///
  /// Loads active consents on build, provides methods to save
  /// signup consents and toggle individual consents.
  const ConsentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentControllerHash();

  @$internal
  @override
  ConsentController create() => ConsentController();
}

String _$consentControllerHash() => r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

/// Manages user consent state for the current user.
///
/// Loads active consents on build, provides methods to save
/// signup consents and toggle individual consents.

abstract class _$ConsentController extends $AsyncNotifier<List<UserConsent>> {
  FutureOr<List<UserConsent>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<UserConsent>>, List<UserConsent>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserConsent>>, List<UserConsent>>,
              AsyncValue<List<UserConsent>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider that checks if the current user has all required consents.
///
/// Used by the route guard to decide whether to redirect to the
/// consent screen.

@ProviderFor(hasRequiredConsents)
const hasRequiredConsentsProvider = HasRequiredConsentsProvider._();

/// Provider that checks if the current user has all required consents.
///
/// Used by the route guard to decide whether to redirect to the
/// consent screen.

final class HasRequiredConsentsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider that checks if the current user has all required consents.
  ///
  /// Used by the route guard to decide whether to redirect to the
  /// consent screen.
  const HasRequiredConsentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasRequiredConsentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasRequiredConsentsHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return hasRequiredConsents(ref);
  }
}

String _$hasRequiredConsentsHash() =>
    r'c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1';
