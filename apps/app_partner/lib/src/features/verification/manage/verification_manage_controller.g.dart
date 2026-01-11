// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_manage_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VerificationManageController)
const verificationManageControllerProvider =
    VerificationManageControllerProvider._();

final class VerificationManageControllerProvider
    extends
        $AsyncNotifierProvider<
          VerificationManageController,
          VerificationManageState
        > {
  const VerificationManageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationManageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationManageControllerHash();

  @$internal
  @override
  VerificationManageController create() => VerificationManageController();
}

String _$verificationManageControllerHash() =>
    r'fd26b42892bf98a4b606018df8cf18a4731c0ea9';

abstract class _$VerificationManageController
    extends $AsyncNotifier<VerificationManageState> {
  FutureOr<VerificationManageState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<VerificationManageState>,
              VerificationManageState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<VerificationManageState>,
                VerificationManageState
              >,
              AsyncValue<VerificationManageState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
