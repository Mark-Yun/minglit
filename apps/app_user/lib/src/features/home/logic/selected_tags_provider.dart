import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the set of selected tag IDs for home feed filtering.
///
/// Multiple tags can be selected simultaneously (OR filter).
class SelectedTagsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Toggles selection of [tagId].
  ///
  /// If already selected, removes it. Otherwise adds it.
  void toggle(String tagId) {
    if (state.contains(tagId)) {
      state = {...state}..remove(tagId);
    } else {
      state = {...state, tagId};
    }
  }

  /// Clears all selected tags.
  void clear() {
    state = const {};
  }
}

/// Provider that holds the set of currently selected tag IDs.
final selectedTagsProvider =
    NotifierProvider<SelectedTagsNotifier, Set<String>>(
  SelectedTagsNotifier.new,
);
