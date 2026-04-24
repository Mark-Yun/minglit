// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_stats_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CheckinStatsController)
const checkinStatsControllerProvider = CheckinStatsControllerFamily._();

final class CheckinStatsControllerProvider
    extends $AsyncNotifierProvider<CheckinStatsController, CheckinStats> {
  const CheckinStatsControllerProvider._({
    required CheckinStatsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'checkinStatsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkinStatsControllerHash();

  @override
  String toString() {
    return r'checkinStatsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CheckinStatsController create() => CheckinStatsController();

  @override
  bool operator ==(Object other) {
    return other is CheckinStatsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkinStatsControllerHash() =>
    r'a1b2c3d4e5f6789012345678901234567890abcd';

final class CheckinStatsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CheckinStatsController,
          AsyncValue<CheckinStats>,
          CheckinStats,
          FutureOr<CheckinStats>,
          String
        > {
  const CheckinStatsControllerFamily._()
    : super(
        retry: null,
        name: r'checkinStatsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CheckinStatsControllerProvider call(String eventId) =>
      CheckinStatsControllerProvider._(argument: eventId, from: this);

  @override
  String toString() => r'checkinStatsControllerProvider';
}

abstract class _$CheckinStatsController extends $AsyncNotifier<CheckinStats> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<CheckinStats> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<CheckinStats>, CheckinStats>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CheckinStats>, CheckinStats>,
              AsyncValue<CheckinStats>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
