// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Member Feature Coordinator**
///
/// Handles all navigation logic related to the Member Management feature.
/// Acts as a bridge between the UI (Screens) and the Router (GoRouter).
///
/// **Role:**
/// - Decides *where* to navigate (Target Route).
/// - Decides *how* to navigate (Push, Go, Replace).
/// - Prepares necessary parameters (Ids, Objects) for the route.
///
/// **Usage:**
/// ```dart
/// ref.read(memberCoordinatorProvider.notifier).goToMemberPermission(...);
/// ```

@ProviderFor(MemberCoordinator)
const memberCoordinatorProvider = MemberCoordinatorProvider._();

/// **Member Feature Coordinator**
///
/// Handles all navigation logic related to the Member Management feature.
/// Acts as a bridge between the UI (Screens) and the Router (GoRouter).
///
/// **Role:**
/// - Decides *where* to navigate (Target Route).
/// - Decides *how* to navigate (Push, Go, Replace).
/// - Prepares necessary parameters (Ids, Objects) for the route.
///
/// **Usage:**
/// ```dart
/// ref.read(memberCoordinatorProvider.notifier).goToMemberPermission(...);
/// ```
final class MemberCoordinatorProvider
    extends $NotifierProvider<MemberCoordinator, void> {
  /// **Member Feature Coordinator**
  ///
  /// Handles all navigation logic related to the Member Management feature.
  /// Acts as a bridge between the UI (Screens) and the Router (GoRouter).
  ///
  /// **Role:**
  /// - Decides *where* to navigate (Target Route).
  /// - Decides *how* to navigate (Push, Go, Replace).
  /// - Prepares necessary parameters (Ids, Objects) for the route.
  ///
  /// **Usage:**
  /// ```dart
  /// ref.read(memberCoordinatorProvider.notifier).goToMemberPermission(...);
  /// ```
  const MemberCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberCoordinatorHash();

  @$internal
  @override
  MemberCoordinator create() => MemberCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$memberCoordinatorHash() => r'12ebaac0e2f590a9672ad30b69b8bfd50edd87ea';

/// **Member Feature Coordinator**
///
/// Handles all navigation logic related to the Member Management feature.
/// Acts as a bridge between the UI (Screens) and the Router (GoRouter).
///
/// **Role:**
/// - Decides *where* to navigate (Target Route).
/// - Decides *how* to navigate (Push, Go, Replace).
/// - Prepares necessary parameters (Ids, Objects) for the route.
///
/// **Usage:**
/// ```dart
/// ref.read(memberCoordinatorProvider.notifier).goToMemberPermission(...);
/// ```

abstract class _$MemberCoordinator extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
