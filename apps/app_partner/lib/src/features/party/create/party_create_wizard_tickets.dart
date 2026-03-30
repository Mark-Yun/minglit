part of 'party_create_wizard_controller.dart';

mixin _PartyCreateWizardTickets on _$PartyCreateWizardController {
  // --- Step 5: Tickets ---
  void _updateMaxParticipants() {
    final total = state.tickets.fold<int>(0, (sum, t) => sum + t.quantity);
    state = state.copyWith(maxParticipants: total);
  }

  void addTicket(TicketTemplate ticket) {
    state = state.copyWith(tickets: [...state.tickets, ticket]);
    _updateMaxParticipants();
  }

  void updateTicket(int index, TicketTemplate ticket) {
    final list = List<TicketTemplate>.from(state.tickets);
    list[index] = ticket;
    state = state.copyWith(tickets: list);
    _updateMaxParticipants();
  }

  void removeTicket(int index) {
    final list = List<TicketTemplate>.from(state.tickets)..removeAt(index);
    state = state.copyWith(tickets: list);
    _updateMaxParticipants();
  }
}
