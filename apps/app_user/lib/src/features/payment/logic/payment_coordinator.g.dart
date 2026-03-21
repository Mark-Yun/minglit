// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentCoordinator)
const paymentCoordinatorProvider = PaymentCoordinatorProvider._();

final class PaymentCoordinatorProvider
    extends
        $FunctionalProvider<
          PaymentCoordinator,
          PaymentCoordinator,
          PaymentCoordinator
        >
    with $Provider<PaymentCoordinator> {
  const PaymentCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentCoordinatorHash();

  @$internal
  @override
  $ProviderElement<PaymentCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentCoordinator create(Ref ref) {
    return paymentCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentCoordinator>(value),
    );
  }
}

String _$paymentCoordinatorHash() =>
    r'c6660b2c43700dd6ccad985a80a28c639555da89';
