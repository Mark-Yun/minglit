/// Ticket-domain ProviderScope overrides for the demo flavor.
///
/// Covers: SocialRepository, StorageRepository, IamportRepository,
/// RecurrenceRuleRepository, TicketRepository.
///
/// IAMport widget render-skip (native plugin bypass) is handled in
/// apps/app_user/lib/main_demo.dart. This file only fakes the EF-calling
/// Repository layer so no network or native plugin is touched.
library;

import 'dart:typed_data';

// ignore: implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../fixtures/demo_tickets.dart';
import '../fixtures/demo_world.dart';
import 'poison_supabase_client.dart';

// ── Social ────────────────────────────────────────────────────────────────────

/// In-memory social interactions list. Mutable so that setInteraction writes
/// survive within a single demo session.
final _mutableSocialInteractions = List<SocialInteraction>.from(
  demoSocialInteractions,
);

class _DemoSocialRepository extends SocialRepository {
  _DemoSocialRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<void> setInteraction({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
    required bool active,
  }) async {
    // Mutate the in-memory list to reflect the new interaction state.
    _mutableSocialInteractions.removeWhere(
      (i) =>
          i.userId == DemoWorld.userId &&
          i.targetId == targetId &&
          i.targetType == targetType &&
          i.interactionType == interactionType,
    );
    if (active) {
      _mutableSocialInteractions.add(
        SocialInteraction(
          userId: DemoWorld.userId,
          targetId: targetId,
          targetType: targetType,
          interactionType: interactionType,
          createdAt: DemoWorld.now,
        ),
      );
    }
  }

  @override
  Future<bool> getInteractionState({
    required String targetId,
    required SocialInteractionType interactionType,
  }) async {
    return _mutableSocialInteractions.any(
      (i) =>
          i.userId == DemoWorld.userId &&
          i.targetId == targetId &&
          i.interactionType == interactionType,
    );
  }

  @override
  Future<void> blockPartner(String partnerId) async {
    await setInteraction(
      targetId: partnerId,
      targetType: SocialTargetType.partner,
      interactionType: SocialInteractionType.block,
      active: true,
    );
  }

  @override
  Future<void> unblockPartner(String partnerId) async {
    await setInteraction(
      targetId: partnerId,
      targetType: SocialTargetType.partner,
      interactionType: SocialInteractionType.block,
      active: false,
    );
  }

  @override
  Future<void> reportPartner({
    required String partnerId,
    required String reason,
    String? description,
  }) async {
    // Demo: record interaction without calling EF.
    await setInteraction(
      targetId: partnerId,
      targetType: SocialTargetType.partner,
      interactionType: SocialInteractionType.report,
      active: true,
    );
  }

  @override
  Future<List<String>> getBlockedPartnerIds() async {
    return _mutableSocialInteractions
        .where(
          (i) =>
              i.userId == DemoWorld.userId &&
              i.targetType == SocialTargetType.partner &&
              i.interactionType == SocialInteractionType.block,
        )
        .map((i) => i.targetId)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getBlockedPartners() async {
    // Return empty — partner profile data is in partner domain fixtures.
    // TODO(P1-5): join with demoPartners from demo_partners.dart when
    // partner domain fixtures are populated.
    return [];
  }

  @override
  Future<int> getInteractionCount({
    required String targetId,
    required SocialInteractionType interactionType,
  }) async {
    return _mutableSocialInteractions
        .where(
          (i) => i.targetId == targetId && i.interactionType == interactionType,
        )
        .length;
  }
}

// ── Storage ───────────────────────────────────────────────────────────────────

class _DemoStorageRepository extends StorageRepository {
  _DemoStorageRepository() : super(supabase: const PoisonSupabaseClient());

  static const _fakeBucket =
      'https://demo.minglit.app/demo-assets';

  @override
  Future<String> uploadFile({
    required XFile file,
    required String bucket,
    String? pathPrefix,
  }) async {
    // Return a deterministic fake URL — no network call.
    final name = file.name.isEmpty ? 'demo-upload.jpg' : file.name;
    final path = pathPrefix != null ? '$pathPrefix/$name' : name;
    return '$_fakeBucket/$bucket/$path';
  }

  @override
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String bucket,
    String? pathPrefix,
    String contentType = 'image/png',
    String extension = '.png',
  }) async {
    final filename = 'demo-upload$extension';
    final path = pathPrefix != null ? '$pathPrefix/$filename' : filename;
    return '$_fakeBucket/$bucket/$path';
  }

  @override
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    // No-op in demo — no actual storage.
  }
}

// ── IAMport ───────────────────────────────────────────────────────────────────

class _DemoIamportRepository extends IamportRepository {
  _DemoIamportRepository() : super(const PoisonSupabaseClient());

  /// Returns a fake successful verification response.
  /// The native IAMport plugin is never invoked; only this EF-calling method
  /// is exercised in the demo flow.
  @override
  Future<Map<String, dynamic>> verifyCertification(String impUid) async {
    // Fake success — mimics the shape returned by identity-verify EF.
    return {
      'success': true,
      'imp_uid': impUid.isEmpty ? 'demo-imp-uid-00001' : impUid,
      'merchant_uid': 'demo-merchant-uid-00001',
      'name': '홍길동',
      'phone': DemoWorld.userPhone,
      'birth': '19900101',
      'gender': 'male',
    };
  }
}

// ── Recurrence rule ───────────────────────────────────────────────────────────

class _DemoRecurrenceRuleRepository extends RecurrenceRuleRepository {
  _DemoRecurrenceRuleRepository() : super(const PoisonSupabaseClient());

  @override
  Future<RecurrenceRule?> getByPartyId(String partyId) async => null;

  @override
  Future<RecurrenceRule?> getById(String id) async => null;

  @override
  Future<RecurrenceRule> create({
    required String partyId,
    required RecurrencePattern pattern,
    required List<int> daysOfWeek,
    required String startTime,
    required String endTime,
    int? monthDay,
    String? endDate,
  }) async {
    // TODO(P1-5): return a fake RecurrenceRule when the partner event-edit
    // flow is wired up. For now this path is unreachable in demo.
    throw UnimplementedError(
      'DEMO MODE: RecurrenceRuleRepository.create is not implemented. '
      'Add a fixture and return it here when the partner recurrence UI is '
      'exercised in the demo flow.',
    );
  }

  @override
  Future<void> update(
    String ruleId, {
    RecurrencePattern? pattern,
    List<int>? daysOfWeek,
    int? monthDay,
    String? startTime,
    String? endTime,
    String? endDate,
  }) async {
    // No-op — demo does not mutate recurrence rules.
  }

  @override
  Future<void> pause(String ruleId) async {}

  @override
  Future<void> resume(String ruleId) async {}

  @override
  Future<void> cancel(String ruleId) async {}
}

// ── Ticket ────────────────────────────────────────────────────────────────────

class _DemoTicketRepository extends TicketRepository {
  _DemoTicketRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<List<Ticket>> getTicketsByEventId(String eventId) async {
    return demoTickets.where((t) => t.eventId == eventId).toList();
  }

  @override
  Future<List<Ticket>> getTicketsByPartyId(String partyId) async {
    // Map party → events; for demo purposes return tickets whose eventId
    // corresponds to known events under the given party.
    final partyEventMap = <String, List<String>>{
      DemoWorld.selfParty1Id: [
        DemoWorld.selfEvent1Id,
        DemoWorld.selfEvent2Id,
      ],
      DemoWorld.selfParty2Id: [DemoWorld.selfEvent3Id],
      DemoWorld.partner2PartyId: [DemoWorld.partner2EventId],
      DemoWorld.partner3PartyId: [DemoWorld.partner3EventId],
      DemoWorld.partner4PartyId: [DemoWorld.partner4EventId],
      DemoWorld.partner5PartyId: [DemoWorld.partner5EventId],
    };
    final eventIds = partyEventMap[partyId] ?? [];
    return demoTickets
        .where((t) => t.eventId != null && eventIds.contains(t.eventId))
        .toList();
  }

  @override
  Future<List<TicketTemplate>> getTicketTemplatesByPartyId(
    String partyId,
  ) async {
    return demoTicketTemplates
        .where((t) => t.partyId == partyId)
        .toList();
  }

  @override
  Future<List<TicketTemplate>> getDefaultTicketsByPartyId(
    String partyId,
  ) async {
    return getTicketTemplatesByPartyId(partyId);
  }

  @override
  Future<Ticket> getTicketById(String id) async {
    return demoTickets.firstWhere(
      (t) => t.id == id,
      orElse: () => throw StateError('DEMO: Ticket $id not found in fixtures'),
    );
  }

  @override
  Future<TicketTemplate> getTicketTemplateById(String id) async {
    return demoTicketTemplates.firstWhere(
      (t) => t.id == id,
      orElse: () =>
          throw StateError('DEMO: TicketTemplate $id not found in fixtures'),
    );
  }

  @override
  Future<TicketTemplate> updateTicketTemplate(TicketTemplate template) async {
    // Return the updated template as-is (no persistence in demo).
    return template;
  }

  @override
  Future<TicketTemplate> createTicketTemplate(TicketTemplate template) async {
    // Return the template as-if created (demo does not persist).
    return template;
  }

  @override
  Future<void> deleteTicketTemplate(String id) async {
    // No-op in demo.
  }

  @override
  Future<Ticket> createTicket(Ticket ticket) async {
    return ticket;
  }

  @override
  Future<Ticket> updateTicket(Ticket ticket) async {
    return ticket;
  }
}

// ── Provider override list ────────────────────────────────────────────────────

List<Override> ticketDomainOverrides() => [
  socialRepositoryProvider.overrideWith((_) => _DemoSocialRepository()),
  storageRepositoryProvider.overrideWith((_) => _DemoStorageRepository()),
  iamportRepositoryProvider.overrideWith((_) => _DemoIamportRepository()),
  recurrenceRuleRepositoryProvider
      .overrideWith((_) => _DemoRecurrenceRuleRepository()),
  ticketRepositoryProvider.overrideWith((_) => _DemoTicketRepository()),
];
