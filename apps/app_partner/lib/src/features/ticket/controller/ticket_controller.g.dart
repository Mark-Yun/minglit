// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TicketController)
const ticketControllerProvider = TicketControllerProvider._();

final class TicketControllerProvider
    extends $AsyncNotifierProvider<TicketController, void> {
  const TicketControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticketControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticketControllerHash();

  @$internal
  @override
  TicketController create() => TicketController();
}

String _$ticketControllerHash() => r'e2da1b2eb0e5c1a1c1be4f9f4033748c900df98f';

abstract class _$TicketController extends $AsyncNotifier<void> {
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

@ProviderFor(ticketDetail)
const ticketDetailProvider = TicketDetailFamily._();

final class TicketDetailProvider
    extends $FunctionalProvider<AsyncValue<Ticket>, Ticket, FutureOr<Ticket>>
    with $FutureModifier<Ticket>, $FutureProvider<Ticket> {
  const TicketDetailProvider._({
    required TicketDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ticketDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ticketDetailHash();

  @override
  String toString() {
    return r'ticketDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Ticket> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Ticket> create(Ref ref) {
    final argument = this.argument as String;
    return ticketDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ticketDetailHash() => r'308bfb15738db3d69e471ca4009ba002b0e5bf23';

final class TicketDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Ticket>, String> {
  const TicketDetailFamily._()
    : super(
        retry: null,
        name: r'ticketDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TicketDetailProvider call(String ticketId) =>
      TicketDetailProvider._(argument: ticketId, from: this);

  @override
  String toString() => r'ticketDetailProvider';
}
