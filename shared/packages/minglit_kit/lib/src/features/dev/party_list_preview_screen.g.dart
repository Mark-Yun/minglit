// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_list_preview_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(previewParties)
const previewPartiesProvider = PreviewPartiesProvider._();

final class PreviewPartiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Party>>,
          List<Party>,
          FutureOr<List<Party>>
        >
    with $FutureModifier<List<Party>>, $FutureProvider<List<Party>> {
  const PreviewPartiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'previewPartiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$previewPartiesHash();

  @$internal
  @override
  $FutureProviderElement<List<Party>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Party>> create(Ref ref) {
    return previewParties(ref);
  }
}

String _$previewPartiesHash() => r'b9e44184b9e5923cec586b4a5ad29ea2a294fee0';
