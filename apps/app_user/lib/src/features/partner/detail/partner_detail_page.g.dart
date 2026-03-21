// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_detail_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a partner by ID for the detail page.

@ProviderFor(partnerDetail)
const partnerDetailProvider = PartnerDetailFamily._();

/// Fetches a partner by ID for the detail page.

final class PartnerDetailProvider extends $FunctionalProvider<
        AsyncValue<Partner?>, Partner?, FutureOr<Partner?>>
    with $FutureModifier<Partner?>, $FutureProvider<Partner?> {
  /// Fetches a partner by ID for the detail page.
  const PartnerDetailProvider._({
    required PartnerDetailFamily super.from,
    required String super.argument,
  }) : super(
          retry: null,
          name: r'partnerDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$partnerDetailHash();

  @override
  String toString() {
    return r'partnerDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Partner?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Partner?> create(Ref ref) {
    final argument = this.argument as String;
    return partnerDetail(ref, partnerId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerDetailHash() => r'e5bb5d7f1c100f3d6b2f95492dd04e6b7d1b46a2';

/// Fetches a partner by ID for the detail page.

final class PartnerDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Partner?>, String> {
  const PartnerDetailFamily._()
      : super(
          retry: null,
          name: r'partnerDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Fetches a partner by ID for the detail page.

  PartnerDetailProvider call({required String partnerId}) =>
      PartnerDetailProvider._(argument: partnerId, from: this);

  @override
  String toString() => r'partnerDetailProvider';
}
