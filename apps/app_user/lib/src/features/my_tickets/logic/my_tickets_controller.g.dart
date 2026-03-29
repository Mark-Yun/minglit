// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_tickets_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MyTicketsController)
const myTicketsControllerProvider = MyTicketsControllerProvider._();

final class MyTicketsControllerProvider
    extends $AsyncNotifierProvider<MyTicketsController, MyTicketsState> {
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
    r'b4d487d7e52af0b7e5a9e2a875ca243564f39938';

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
