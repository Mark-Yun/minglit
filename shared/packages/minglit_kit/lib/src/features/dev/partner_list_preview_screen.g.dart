// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_list_preview_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local provider to fetch partners for preview.

@ProviderFor(previewPartners)
const previewPartnersProvider = PreviewPartnersProvider._();

/// Local provider to fetch partners for preview.

final class PreviewPartnersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Partner>>,
          List<Partner>,
          FutureOr<List<Partner>>
        >
    with $FutureModifier<List<Partner>>, $FutureProvider<List<Partner>> {
  /// Local provider to fetch partners for preview.
  const PreviewPartnersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'previewPartnersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$previewPartnersHash();

  @$internal
  @override
  $FutureProviderElement<List<Partner>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Partner>> create(Ref ref) {
    return previewPartners(ref);
  }
}

String _$previewPartnersHash() => r'850a0e3dc1235c981e48be7b656730930e65b68a';
