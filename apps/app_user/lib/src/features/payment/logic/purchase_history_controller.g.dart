// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Purchase History Controller**
///
/// Manages the state of the user's purchase history.
/// Fetches data from EventRepository.

@ProviderFor(PurchaseHistoryController)
const purchaseHistoryControllerProvider = PurchaseHistoryControllerProvider._();

/// **Purchase History Controller**
///
/// Manages the state of the user's purchase history.
/// Fetches data from EventRepository.
final class PurchaseHistoryControllerProvider
    extends
        $AsyncNotifierProvider<
          PurchaseHistoryController,
          List<EventApplication>
        > {
  /// **Purchase History Controller**
  ///
  /// Manages the state of the user's purchase history.
  /// Fetches data from EventRepository.
  const PurchaseHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purchaseHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purchaseHistoryControllerHash();

  @$internal
  @override
  PurchaseHistoryController create() => PurchaseHistoryController();
}

String _$purchaseHistoryControllerHash() =>
    r'dd139e674d488a6a455c47e12e63cdf7be8ba060';

/// **Purchase History Controller**
///
/// Manages the state of the user's purchase history.
/// Fetches data from EventRepository.

abstract class _$PurchaseHistoryController
    extends $AsyncNotifier<List<EventApplication>> {
  FutureOr<List<EventApplication>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<AsyncValue<List<EventApplication>>, List<EventApplication>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EventApplication>>,
                List<EventApplication>
              >,
              AsyncValue<List<EventApplication>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
