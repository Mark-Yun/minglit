// Type-safe metadata key registry for Party and Event models.
//
// Provides compile-time type safety for accessing and updating metadata
// stored in `Map<String, dynamic>` fields via sealed class hierarchy.

/// Base sealed class for metadata keys with type safety.
///
/// Each subtype ([BoolMetaKey], [StringMetaKey], [IntMetaKey]) enforces
/// a specific value type and provides parsing logic.
sealed class MetadataKey<T> {
  /// Creates a metadata key with a string identifier and default value.
  const MetadataKey(this.key, this.defaultValue);

  /// The string key used in the metadata map.
  final String key;

  /// The default value returned if the key is missing or null.
  final T defaultValue;

  /// Parses a raw value from the metadata map to type [T].
  ///
  /// Returns [defaultValue] if [raw] is null or cannot be cast to [T].
  T parse(dynamic raw);
}

/// Metadata key for boolean values.
final class BoolMetaKey extends MetadataKey<bool> {
  /// Creates a boolean metadata key.
  // ignore: avoid_positional_boolean_parameters
  const BoolMetaKey(super.key, super.defaultValue);

  @override
  bool parse(dynamic raw) => (raw as bool?) ?? defaultValue;
}

/// Metadata key for string values.
final class StringMetaKey extends MetadataKey<String> {
  /// Creates a string metadata key.
  const StringMetaKey(super.key, super.defaultValue);

  @override
  String parse(dynamic raw) => raw as String? ?? defaultValue;
}

/// Metadata key for integer values.
final class IntMetaKey extends MetadataKey<int> {
  /// Creates an integer metadata key.
  const IntMetaKey(super.key, super.defaultValue);

  @override
  int parse(dynamic raw) => raw as int? ?? defaultValue;
}

/// Registry of predefined metadata keys for Party and Event models.
///
/// Provides static const keys for common metadata fields with type safety.
abstract final class MetaKeys {
  /// Whether to show the participant list in the UI.
  ///
  /// Default: `true`
  static const showParticipantList = BoolMetaKey('show_participant_list', true);

  /// Visibility level of the party/event.
  ///
  /// Default: `'public'`
  static const visibility = StringMetaKey('visibility', 'public');

  /// Maximum size of the waitlist.
  ///
  /// Default: `0` (no limit)
  static const maxWaitlistSize = IntMetaKey('max_waitlist_size', 0);
}

/// Extension methods for type-safe metadata access on [Map<String, dynamic>].
extension MetadataMapX on Map<String, dynamic> {
  /// Retrieves a typed value from the metadata map.
  ///
  /// Uses the [key]'s parse method to safely extract and convert the value.
  /// Returns the key's default value if the key is missing or null.
  ///
  /// Example:
  /// ```dart
  /// final metadata = {'show_participant_list': false};
  /// final show = metadata.getValue(MetaKeys.showParticipantList); // false
  /// ```
  T getValue<T>(MetadataKey<T> key) => key.parse(this[key.key]);

  /// Returns a new map with the given key-value pair added or updated.
  ///
  /// Creates a shallow copy of the current map with the new value.
  ///
  /// Example:
  /// ```dart
  /// final metadata = {'visibility': 'public'};
  /// final updated = metadata.withValue(MetaKeys.maxWaitlistSize, 10);
  /// // {'visibility': 'public', 'max_waitlist_size': 10}
  /// ```
  Map<String, dynamic> withValue<T>(MetadataKey<T> key, T value) => {
    ...this,
    key.key: value,
  };
}
