// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for authentication actions (Sign In, Sign Out).
/// Handles the state of the *request* (loading, error, success).

@ProviderFor(AuthController)
const authControllerProvider = AuthControllerProvider._();

/// Controller for authentication actions (Sign In, Sign Out).
/// Handles the state of the *request* (loading, error, success).
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Controller for authentication actions (Sign In, Sign Out).
  /// Handles the state of the *request* (loading, error, success).
  const AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'83bdcfe9c40a6c14c657921ef1e6560fa120b067';

/// Controller for authentication actions (Sign In, Sign Out).
/// Handles the state of the *request* (loading, error, success).

abstract class _$AuthController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
