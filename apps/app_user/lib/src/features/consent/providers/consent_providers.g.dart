// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the current user has completed all required consents.
///
/// keepAlive so the value is cached app-wide and only re-fetched on
/// explicit invalidation (e.g. after saving consents).

@ProviderFor(HasRequiredConsents)
const hasRequiredConsentsProvider = HasRequiredConsentsProvider._();

/// Whether the current user has completed all required consents.
///
/// keepAlive so the value is cached app-wide and only re-fetched on
/// explicit invalidation (e.g. after saving consents).
final class HasRequiredConsentsProvider
    extends $AsyncNotifierProvider<HasRequiredConsents, bool> {
  /// Whether the current user has completed all required consents.
  ///
  /// keepAlive so the value is cached app-wide and only re-fetched on
  /// explicit invalidation (e.g. after saving consents).
  const HasRequiredConsentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasRequiredConsentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasRequiredConsentsHash();

  @$internal
  @override
  HasRequiredConsents create() => HasRequiredConsents();
}

String _$hasRequiredConsentsHash() =>
    r'd69d3d32e46a712e2ba88aca1d586df2332b960a';

/// Whether the current user has completed all required consents.
///
/// keepAlive so the value is cached app-wide and only re-fetched on
/// explicit invalidation (e.g. after saving consents).

abstract class _$HasRequiredConsents extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
