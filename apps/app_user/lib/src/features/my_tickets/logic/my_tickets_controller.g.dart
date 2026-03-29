// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_tickets_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fix #639: MyTicketsController — upcoming/past ticket separation + today event detection.
///
/// Fetches active tickets (paid/approved) and splits them by event start time.

@ProviderFor(MyTicketsController)
const myTicketsControllerProvider = MyTicketsControllerProvider._();

/// Fix #639: MyTicketsController — upcoming/past ticket separation + today event detection.
///
/// Fetches active tickets (paid/approved) and splits them by event start time.
final class MyTicketsControllerProvider
    extends $AsyncNotifierProvider<MyTicketsController, MyTicketsState> {
  /// Fix #639: MyTicketsController — upcoming/past ticket separation + today event detection.
  ///
  /// Fetches active tickets (paid/approved) and splits them by event start time.
  const MyTicketsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTicketsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTicketsControllerHash();

  @$internal
  @override
  MyTicketsController create() => MyTicketsController();
}

String _$myTicketsControllerHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// Fix #639: MyTicketsController — upcoming/past ticket separation + today event detection.
///
/// Fetches active tickets (paid/approved) and splits them by event start time.

abstract class _$MyTicketsController extends $AsyncNotifier<MyTicketsState> {
  FutureOr<MyTicketsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<MyTicketsState>, MyTicketsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MyTicketsState>, MyTicketsState>,
              AsyncValue<MyTicketsState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
