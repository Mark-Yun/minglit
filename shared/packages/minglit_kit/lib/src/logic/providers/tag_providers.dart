import 'dart:async';

import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/tag.dart';
import 'package:minglit_kit/src/data/repositories/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_providers.g.dart';

/// Provides the list of featured tags.
///
/// Kept alive indefinitely — invalidate manually when stale.
@Riverpod(keepAlive: true)
Future<List<Tag>> featuredTags(Ref ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getFeaturedTags();
}

/// Provides the list of trending tags.
///
/// Kept alive indefinitely — invalidate manually when stale.
@Riverpod(keepAlive: true)
Future<List<Tag>> trendingTags(Ref ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTrendingTags();
}

/// Searches tags matching [query].
///
/// Empty query returns an empty list without calling the server.
@riverpod
Future<List<Tag>> tagSearch(Ref ref, String query) async {
  if (query.trim().isEmpty) return const [];
  final repository = ref.watch(tagRepositoryProvider);
  return repository.searchTags(query.trim());
}

/// Provides the current user's interest tags.
@riverpod
Future<List<Tag>> userInterestTags(Ref ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getUserInterestTags();
}

/// Provides personalized event recommendations based on user interest tags.
@riverpod
Future<List<Event>> tagRecommendationFeed(Ref ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return repository.getTagRecommendations();
}
