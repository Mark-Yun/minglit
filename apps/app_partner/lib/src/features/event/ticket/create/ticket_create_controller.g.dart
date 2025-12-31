// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_create_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TicketCreateController)
const ticketCreateControllerProvider = TicketCreateControllerProvider._();

final class TicketCreateControllerProvider
    extends $AsyncNotifierProvider<TicketCreateController, void> {
  const TicketCreateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketCreateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketCreateControllerHash();

  @$internal
  @override
  TicketCreateController create() => TicketCreateController();
}

String _$ticketCreateControllerHash() =>
    r'ece432e19f8927742ad197da3456294e2172a95c';

abstract class _$TicketCreateController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
