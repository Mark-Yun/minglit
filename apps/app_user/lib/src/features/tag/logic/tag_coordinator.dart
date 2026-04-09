import 'dart:async';

import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final tagCoordinatorProvider = Provider<TagCoordinator>((ref) {
  return TagCoordinator(ref.read(goRouterProvider));
});

/// Coordinator for tag-related navigation within the tag feature.
class TagCoordinator {
  TagCoordinator(this._router);

  final GoRouter _router;

  /// Navigates to the event list for a given tag.
  void goToTagEventList(String tagId, String tagName) {
    unawaited(
      _router.push(TagEventListRoute(tagId: tagId, tagName: tagName).location),
    );
  }
}
