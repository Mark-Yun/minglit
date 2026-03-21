// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_interaction_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the state of a single social interaction
/// (like, subscribe, bookmark, block).

@ProviderFor(SocialInteractionController)
const socialInteractionControllerProvider =
    SocialInteractionControllerFamily._();

/// Manages the state of a single social interaction
/// (like, subscribe, bookmark, block).
final class SocialInteractionControllerProvider
    extends $AsyncNotifierProvider<SocialInteractionController, bool> {
  /// Manages the state of a single social interaction
  /// (like, subscribe, bookmark, block).
  const SocialInteractionControllerProvider._({
    required SocialInteractionControllerFamily super.from,
    required ({
      String targetId,
      SocialTargetType targetType,
      SocialInteractionType interactionType,
    })
        super.argument,
  }) : super(
          retry: null,
          name: r'socialInteractionControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$socialInteractionControllerHash();

  @override
  String toString() {
    return r'socialInteractionControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SocialInteractionController create() => SocialInteractionController();

  @override
  bool operator ==(Object other) {
    return other is SocialInteractionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$socialInteractionControllerHash() =>
    r'4a7d06244ed794a8f25ea553b0b0cc20eb602360';

/// Manages the state of a single social interaction
/// (like, subscribe, bookmark, block).

final class SocialInteractionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            SocialInteractionController,
            AsyncValue<bool>,
            bool,
            FutureOr<bool>,
            ({
              String targetId,
              SocialTargetType targetType,
              SocialInteractionType interactionType,
            })> {
  const SocialInteractionControllerFamily._()
      : super(
          retry: null,
          name: r'socialInteractionControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Manages the state of a single social interaction
  /// (like, subscribe, bookmark, block).

  SocialInteractionControllerProvider call({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) =>
      SocialInteractionControllerProvider._(
        argument: (
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
        ),
        from: this,
      );

  @override
  String toString() => r'socialInteractionControllerProvider';
}

/// Manages the state of a single social interaction
/// (like, subscribe, bookmark, block).

abstract class _$SocialInteractionController extends $AsyncNotifier<bool> {
  late final _$args = ref.$arg as ({
    String targetId,
    SocialTargetType targetType,
    SocialInteractionType interactionType,
  });
  String get targetId => _$args.targetId;
  SocialTargetType get targetType => _$args.targetType;
  SocialInteractionType get interactionType => _$args.interactionType;

  FutureOr<bool> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      targetId: _$args.targetId,
      targetType: _$args.targetType,
      interactionType: _$args.interactionType,
    );
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<bool>, bool>,
        AsyncValue<bool>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
