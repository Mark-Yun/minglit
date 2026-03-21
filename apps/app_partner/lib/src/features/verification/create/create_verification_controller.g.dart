// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_verification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateVerificationController)
const createVerificationControllerProvider =
    CreateVerificationControllerProvider._();

final class CreateVerificationControllerProvider
    extends
        $NotifierProvider<
          CreateVerificationController,
          CreateVerificationState
        > {
  const CreateVerificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createVerificationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createVerificationControllerHash();

  @$internal
  @override
  CreateVerificationController create() => CreateVerificationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateVerificationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateVerificationState>(value),
    );
  }
}

String _$createVerificationControllerHash() =>
    r'9a8ddea4683fb935dbddd68a00e7e3313b173a21';

abstract class _$CreateVerificationController
    extends $Notifier<CreateVerificationState> {
  CreateVerificationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<CreateVerificationState, CreateVerificationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateVerificationState, CreateVerificationState>,
              CreateVerificationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
