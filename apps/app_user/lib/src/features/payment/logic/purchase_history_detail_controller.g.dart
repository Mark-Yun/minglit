// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_history_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a single application with full event+ticket data for the detail
/// page. Tries the cached list first to avoid an extra round-trip when the
/// user navigates from PurchaseHistoryPage.

@ProviderFor(purchaseHistoryDetail)
const purchaseHistoryDetailProvider = PurchaseHistoryDetailFamily._();

/// Fetches a single application with full event+ticket data for the detail
/// page. Tries the cached list first to avoid an extra round-trip when the
/// user navigates from PurchaseHistoryPage.

final class PurchaseHistoryDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventApplication?>,
          EventApplication?,
          FutureOr<EventApplication?>
        >
    with
        $FutureModifier<EventApplication?>,
        $FutureProvider<EventApplication?> {
  /// Fetches a single application with full event+ticket data for the detail
  /// page. Tries the cached list first to avoid an extra round-trip when the
  /// user navigates from PurchaseHistoryPage.
  const PurchaseHistoryDetailProvider._({
    required PurchaseHistoryDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'purchaseHistoryDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$purchaseHistoryDetailHash();

  @override
  String toString() {
    return r'purchaseHistoryDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EventApplication?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EventApplication?> create(Ref ref) {
    final argument = this.argument as String;
    return purchaseHistoryDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PurchaseHistoryDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$purchaseHistoryDetailHash() =>
    r'd38e0c544b2b47090b27201322362764e4e148af';

/// Fetches a single application with full event+ticket data for the detail
/// page. Tries the cached list first to avoid an extra round-trip when the
/// user navigates from PurchaseHistoryPage.

final class PurchaseHistoryDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EventApplication?>, String> {
  const PurchaseHistoryDetailFamily._()
    : super(
        retry: null,
        name: r'purchaseHistoryDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single application with full event+ticket data for the detail
  /// page. Tries the cached list first to avoid an extra round-trip when the
  /// user navigates from PurchaseHistoryPage.

  PurchaseHistoryDetailProvider call(String applicationId) =>
      PurchaseHistoryDetailProvider._(argument: applicationId, from: this);

  @override
  String toString() => r'purchaseHistoryDetailProvider';
}
