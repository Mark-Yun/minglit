// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_group_checkin_stats_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EntryGroupCheckinStatsController)
const entryGroupCheckinStatsControllerProvider =
    EntryGroupCheckinStatsControllerFamily._();

final class EntryGroupCheckinStatsControllerProvider
    extends
        $AsyncNotifierProvider<
          EntryGroupCheckinStatsController,
          List<EntryGroupCheckinStats>
        > {
  const EntryGroupCheckinStatsControllerProvider._({
    required EntryGroupCheckinStatsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'entryGroupCheckinStatsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$entryGroupCheckinStatsControllerHash();

  @override
  String toString() {
    return r'entryGroupCheckinStatsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EntryGroupCheckinStatsController create() =>
      EntryGroupCheckinStatsController();

  @override
  bool operator ==(Object other) {
    return other is EntryGroupCheckinStatsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$entryGroupCheckinStatsControllerHash() =>
    r'b2c3d4e5f67890123456789012345678901234ab';

final class EntryGroupCheckinStatsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          EntryGroupCheckinStatsController,
          AsyncValue<List<EntryGroupCheckinStats>>,
          List<EntryGroupCheckinStats>,
          FutureOr<List<EntryGroupCheckinStats>>,
          String
        > {
  const EntryGroupCheckinStatsControllerFamily._()
    : super(
        retry: null,
        name: r'entryGroupCheckinStatsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EntryGroupCheckinStatsControllerProvider call(String eventId) =>
      EntryGroupCheckinStatsControllerProvider._(
        argument: eventId,
        from: this,
      );

  @override
  String toString() => r'entryGroupCheckinStatsControllerProvider';
}

abstract class _$EntryGroupCheckinStatsController
    extends $AsyncNotifier<List<EntryGroupCheckinStats>> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<List<EntryGroupCheckinStats>> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<EntryGroupCheckinStats>>,
              List<EntryGroupCheckinStats>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EntryGroupCheckinStats>>,
                List<EntryGroupCheckinStats>
              >,
              AsyncValue<List<EntryGroupCheckinStats>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
