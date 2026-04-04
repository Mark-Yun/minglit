// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages shared account deletion state for the signed-in user.

@ProviderFor(AccountDeletionController)
const accountDeletionControllerProvider = AccountDeletionControllerProvider._();

/// Manages shared account deletion state for the signed-in user.
final class AccountDeletionControllerProvider
    extends $AsyncNotifierProvider<AccountDeletionController, DeletionStatus?> {
  /// Manages shared account deletion state for the signed-in user.
  const AccountDeletionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionControllerHash();

  @$internal
  @override
  AccountDeletionController create() => AccountDeletionController();
}

String _$accountDeletionControllerHash() =>
    r'5c4b4358ca6c6931e5384c74f29ba9708479d558';

/// Manages shared account deletion state for the signed-in user.

abstract class _$AccountDeletionController
    extends $AsyncNotifier<DeletionStatus?> {
  FutureOr<DeletionStatus?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<DeletionStatus?>, DeletionStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DeletionStatus?>, DeletionStatus?>,
              AsyncValue<DeletionStatus?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
