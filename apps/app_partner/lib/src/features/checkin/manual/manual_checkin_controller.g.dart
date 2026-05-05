// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_checkin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
///
/// - 초기 로드: `get_event_participants_for_checkin` RPC
/// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트

@ProviderFor(ManualCheckinController)
const manualCheckinControllerProvider = ManualCheckinControllerFamily._();

/// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
///
/// - 초기 로드: `get_event_participants_for_checkin` RPC
/// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트
final class ManualCheckinControllerProvider
    extends
        $AsyncNotifierProvider<
          ManualCheckinController,
          List<CheckinParticipant>
        > {
  /// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
  ///
  /// - 초기 로드: `get_event_participants_for_checkin` RPC
  /// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트
  const ManualCheckinControllerProvider._({
    required ManualCheckinControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'manualCheckinControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$manualCheckinControllerHash();

  @override
  String toString() {
    return r'manualCheckinControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ManualCheckinController create() => ManualCheckinController();

  @override
  bool operator ==(Object other) {
    return other is ManualCheckinControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$manualCheckinControllerHash() =>
    r'aef24453126f811f236acca34f256a44baf94dc6';

/// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
///
/// - 초기 로드: `get_event_participants_for_checkin` RPC
/// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트

final class ManualCheckinControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ManualCheckinController,
          AsyncValue<List<CheckinParticipant>>,
          List<CheckinParticipant>,
          FutureOr<List<CheckinParticipant>>,
          String
        > {
  const ManualCheckinControllerFamily._()
    : super(
        retry: null,
        name: r'manualCheckinControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
  ///
  /// - 초기 로드: `get_event_participants_for_checkin` RPC
  /// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트

  ManualCheckinControllerProvider call(String eventId) =>
      ManualCheckinControllerProvider._(argument: eventId, from: this);

  @override
  String toString() => r'manualCheckinControllerProvider';
}

/// 이벤트 참가자 목록 + 수동 체크인 처리 컨트롤러.
///
/// - 초기 로드: `get_event_participants_for_checkin` RPC
/// - 체크인 처리: `process_manual_checkin` RPC + optimistic 업데이트

abstract class _$ManualCheckinController
    extends $AsyncNotifier<List<CheckinParticipant>> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<List<CheckinParticipant>> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<CheckinParticipant>>,
              List<CheckinParticipant>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CheckinParticipant>>,
                List<CheckinParticipant>
              >,
              AsyncValue<List<CheckinParticipant>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
