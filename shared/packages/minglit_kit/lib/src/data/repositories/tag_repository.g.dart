// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for TagRepository.

@ProviderFor(tagRepository)
const tagRepositoryProvider = TagRepositoryProvider._();

/// Provider for TagRepository.

final class TagRepositoryProvider
    extends $FunctionalProvider<TagRepository, TagRepository, TagRepository>
    with $Provider<TagRepository> {
  /// Provider for TagRepository.
  const TagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRepositoryHash();

  @$internal
  @override
  $ProviderElement<TagRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagRepository create(Ref ref) {
    return tagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagRepository>(value),
    );
  }
}

String _$tagRepositoryHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';
