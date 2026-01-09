// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_guard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StaffGuard)
const staffGuardProvider = StaffGuardProvider._();

final class StaffGuardProvider
    extends $AsyncNotifierProvider<StaffGuard, User?> {
  const StaffGuardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffGuardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffGuardHash();

  @$internal
  @override
  StaffGuard create() => StaffGuard();
}

String _$staffGuardHash() => r'061cbb9a5316b56404a8eab8bbbb8449d9ae2ce5';

abstract class _$StaffGuard extends $AsyncNotifier<User?> {
  FutureOr<User?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<User?>, User?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<User?>, User?>,
              AsyncValue<User?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
