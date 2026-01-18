// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_interaction_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocialInteractionController)
const socialInteractionControllerProvider =
    SocialInteractionControllerFamily._();

final class SocialInteractionControllerProvider
    extends
        $AsyncNotifierProvider<SocialInteractionController, InteractionState> {
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
    r'0df98172a836fb63cfc1bb1166d6ef069d1b8ef5';

final class SocialInteractionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SocialInteractionController,
          AsyncValue<InteractionState>,
          InteractionState,
          FutureOr<InteractionState>,
          ({
            String targetId,
            SocialTargetType targetType,
            SocialInteractionType interactionType,
          })
        > {
  const SocialInteractionControllerFamily._()
    : super(
        retry: null,
        name: r'socialInteractionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SocialInteractionControllerProvider call({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) => SocialInteractionControllerProvider._(
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

abstract class _$SocialInteractionController
    extends $AsyncNotifier<InteractionState> {
  late final _$args =
      ref.$arg
          as ({
            String targetId,
            SocialTargetType targetType,
            SocialInteractionType interactionType,
          });
  String get targetId => _$args.targetId;
  SocialTargetType get targetType => _$args.targetType;
  SocialInteractionType get interactionType => _$args.interactionType;

  FutureOr<InteractionState> build({
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
    final ref =
        this.ref as $Ref<AsyncValue<InteractionState>, InteractionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<InteractionState>, InteractionState>,
              AsyncValue<InteractionState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
