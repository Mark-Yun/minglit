
import 'package:app_partner/src/routing/app_router.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_coordinator.g.dart';

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
@riverpod
class MemberCoordinator extends _$MemberCoordinator {
  @override
  void build() {
    // Stateless coordinator
  }

  /// Navigates to the **Member Permission Detail** page.
  ///
  /// - [partnerId]: The ID of the organization.
  /// - [targetUserId]: The ID of the member to edit.
  void goToMemberPermission(String partnerId, String targetUserId) {
    // Create type-safe route object
    final route = MemberPermissionRoute(
      partnerId: partnerId,
      targetUserId: targetUserId,
    );

    // Push the route onto the stack
    // Note: Uses global navigator key from RouterProvider to access context.
    route.push(
      ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext!,
    );
  }
}
