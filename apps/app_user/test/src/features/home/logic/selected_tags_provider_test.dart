import 'package:app_user/src/features/home/logic/selected_tags_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/test_utils.dart';

void main() {
  group('SelectedTagsNotifier', () {
    test('initial state is empty set', () {
      final container = createContainer();

      expect(container.read(selectedTagsProvider), isEmpty);
    });

    test('toggle adds tag when not selected', () {
      final container = createContainer();

      container.read(selectedTagsProvider.notifier).toggle('tag_1');

      expect(container.read(selectedTagsProvider), {'tag_1'});
    });

    test('toggle removes tag when already selected', () {
      final container = createContainer();
      container.read(selectedTagsProvider.notifier).toggle('tag_1');

      container.read(selectedTagsProvider.notifier).toggle('tag_1');

      expect(container.read(selectedTagsProvider), isEmpty);
    });

    test('toggle is independent for different tags', () {
      final container = createContainer();

      container.read(selectedTagsProvider.notifier).toggle('tag_1');
      container.read(selectedTagsProvider.notifier).toggle('tag_2');

      expect(
        container.read(selectedTagsProvider),
        {'tag_1', 'tag_2'},
      );
    });

    test('toggle one tag does not affect other selected tags', () {
      final container = createContainer();
      container.read(selectedTagsProvider.notifier).toggle('tag_1');
      container.read(selectedTagsProvider.notifier).toggle('tag_2');

      container.read(selectedTagsProvider.notifier).toggle('tag_1');

      expect(container.read(selectedTagsProvider), {'tag_2'});
    });

    test('clear resets state to empty set', () {
      final container = createContainer();
      container.read(selectedTagsProvider.notifier).toggle('tag_1');
      container.read(selectedTagsProvider.notifier).toggle('tag_2');

      container.read(selectedTagsProvider.notifier).clear();

      expect(container.read(selectedTagsProvider), isEmpty);
    });

    test('clear on empty state stays empty', () {
      final container = createContainer();

      container.read(selectedTagsProvider.notifier).clear();

      expect(container.read(selectedTagsProvider), isEmpty);
    });
  });
}
