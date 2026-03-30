// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountDeletionCoordinator)
const accountDeletionCoordinatorProvider =
    AccountDeletionCoordinatorProvider._();

final class AccountDeletionCoordinatorProvider
    extends
        $FunctionalProvider<
          AccountDeletionCoordinator,
          AccountDeletionCoordinator,
          AccountDeletionCoordinator
        >
    with $Provider<AccountDeletionCoordinator> {
  const AccountDeletionCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionCoordinatorHash();

  @$internal
  @override
  $ProviderElement<AccountDeletionCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountDeletionCoordinator create(Ref ref) {
    return accountDeletionCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDeletionCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDeletionCoordinator>(value),
    );
  }
}

String _$accountDeletionCoordinatorHash() =>
    r'4b9281d677e249a7f622514e89afa4cb3170ce20';
