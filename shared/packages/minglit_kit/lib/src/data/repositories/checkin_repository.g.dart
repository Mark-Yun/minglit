// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [CheckinRepository].

@ProviderFor(checkinRepository)
const checkinRepositoryProvider = CheckinRepositoryProvider._();

/// Provides the [CheckinRepository].

final class CheckinRepositoryProvider extends $FunctionalProvider<
    CheckinRepository,
    CheckinRepository,
    CheckinRepository> with $Provider<CheckinRepository> {
  /// Provides the [CheckinRepository].
  const CheckinRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'checkinRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$checkinRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheckinRepository> $createElement(
    $ProviderPointer pointer,
  ) =>
      $ProviderElement(pointer);

  @override
  CheckinRepository create(Ref ref) {
    return checkinRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckinRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckinRepository>(value),
    );
  }
}

String _$checkinRepositoryHash() => r'6eb7d58a311c46355492205d40aa8c025d8fd97c';
