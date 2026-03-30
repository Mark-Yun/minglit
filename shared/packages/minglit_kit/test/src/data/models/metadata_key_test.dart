import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/metadata_key.dart';

void main() {
  group('MetadataMapX.getValue', () {
    test('returns default value when key is missing from empty map', () {
      const metadata = <String, dynamic>{};

      expect(metadata.getValue(MetaKeys.showParticipantList), isTrue);
      expect(metadata.getValue(MetaKeys.visibility), 'public');
      expect(metadata.getValue(MetaKeys.maxWaitlistSize), 0);
    });

    test('returns stored value when key is present in map', () {
      final metadata = <String, dynamic>{
        'show_participant_list': false,
        'visibility': 'private',
        'max_waitlist_size': 10,
      };

      expect(metadata.getValue(MetaKeys.showParticipantList), isFalse);
      expect(metadata.getValue(MetaKeys.visibility), 'private');
      expect(metadata.getValue(MetaKeys.maxWaitlistSize), 10);
    });
  });

  group('MetadataMapX.withValue', () {
    test('produces correct map with new key added', () {
      const metadata = <String, dynamic>{};
      final updated = metadata.withValue(MetaKeys.visibility, 'private');

      expect(updated['visibility'], 'private');
      expect(updated.length, 1);
    });

    test('produces correct map with existing key updated', () {
      final metadata = <String, dynamic>{'visibility': 'public'};
      final updated = metadata.withValue(MetaKeys.maxWaitlistSize, 5);

      expect(updated['visibility'], 'public');
      expect(updated['max_waitlist_size'], 5);
      expect(updated.length, 2);
    });

    test('does not mutate original map', () {
      final metadata = <String, dynamic>{'visibility': 'public'};
      final _ = metadata.withValue(MetaKeys.visibility, 'private');

      expect(metadata['visibility'], 'public');
    });
  });

  group('BoolMetaKey.parse', () {
    test('handles bool value correctly', () {
      const key = BoolMetaKey('test_bool', true);

      expect(key.parse(false), isFalse);
      expect(key.parse(true), isTrue);
      expect(key.parse(null), isTrue); // falls back to defaultValue
    });
  });

  group('StringMetaKey.parse', () {
    test('handles String value correctly', () {
      const key = StringMetaKey('test_str', 'default');

      expect(key.parse('hello'), 'hello');
      expect(key.parse(null), 'default'); // falls back to defaultValue
    });
  });

  group('IntMetaKey.parse', () {
    test('handles int value correctly', () {
      const key = IntMetaKey('test_int', 0);

      expect(key.parse(42), 42);
      expect(key.parse(null), 0); // falls back to defaultValue
    });
  });

  group('MetaKeys static constants', () {
    test(
      'all MetaKeys static constants are accessible with correct defaults',
      () {
        expect(MetaKeys.showParticipantList.key, 'show_participant_list');
        expect(MetaKeys.showParticipantList.defaultValue, isTrue);

        expect(MetaKeys.visibility.key, 'visibility');
        expect(MetaKeys.visibility.defaultValue, 'public');

        expect(MetaKeys.maxWaitlistSize.key, 'max_waitlist_size');
        expect(MetaKeys.maxWaitlistSize.defaultValue, 0);
      },
    );
  });
}
