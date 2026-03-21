// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(onboardingState)
const onboardingStateProvider = OnboardingStateProvider._();

final class OnboardingStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<OnboardingState>,
          OnboardingState,
          FutureOr<OnboardingState>
        >
    with $FutureModifier<OnboardingState>, $FutureProvider<OnboardingState> {
  const OnboardingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingStateHash();

  @$internal
  @override
  $FutureProviderElement<OnboardingState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OnboardingState> create(Ref ref) {
    return onboardingState(ref);
  }
}

String _$onboardingStateHash() => r'faf114a70610699003a96eef323b452f30271d75';
