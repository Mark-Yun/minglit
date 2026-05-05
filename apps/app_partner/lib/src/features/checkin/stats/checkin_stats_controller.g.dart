// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_stats_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 이벤트 체크인 현황 컨트롤러.
///
/// - `get_event_checkin_stats` RPC로 초기 데이터 로드
/// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
/// - Realtime 연결 종료 시 30초 폴링으로 폴백

@ProviderFor(CheckinStatsController)
const checkinStatsControllerProvider = CheckinStatsControllerFamily._();

/// 이벤트 체크인 현황 컨트롤러.
///
/// - `get_event_checkin_stats` RPC로 초기 데이터 로드
/// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
/// - Realtime 연결 종료 시 30초 폴링으로 폴백
final class CheckinStatsControllerProvider
    extends $AsyncNotifierProvider<CheckinStatsController, CheckinStats> {
  /// 이벤트 체크인 현황 컨트롤러.
  ///
  /// - `get_event_checkin_stats` RPC로 초기 데이터 로드
  /// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
  /// - Realtime 연결 종료 시 30초 폴링으로 폴백
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
    return other is CheckinStatsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkinStatsControllerHash() =>
    r'f11e2088605459dbecdedb5d0e2abdf9f540caf1';

/// 이벤트 체크인 현황 컨트롤러.
///
/// - `get_event_checkin_stats` RPC로 초기 데이터 로드
/// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
/// - Realtime 연결 종료 시 30초 폴링으로 폴백

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

  /// 이벤트 체크인 현황 컨트롤러.
  ///
  /// - `get_event_checkin_stats` RPC로 초기 데이터 로드
  /// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
  /// - Realtime 연결 종료 시 30초 폴링으로 폴백

  CheckinStatsControllerProvider call(String eventId) =>
      CheckinStatsControllerProvider._(argument: eventId, from: this);

  @override
  String toString() => r'checkinStatsControllerProvider';
}

/// 이벤트 체크인 현황 컨트롤러.
///
/// - `get_event_checkin_stats` RPC로 초기 데이터 로드
/// - Supabase Realtime `event_participants` 채널 구독으로 실시간 갱신
/// - Realtime 연결 종료 시 30초 폴링으로 폴백

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
