part of 'event_repository.dart';

mixin _EventRepositoryPartnerQueries on _SupabaseEventContext {
  /// [Partner Dashboard]
  /// Counts pending review applications for a specific partner.
  Future<int> getPendingApplicationCount(String partnerId) async {
    try {
      // Fix #1597: 2-step query to guarantee partner scoping.
      // Single-level join filter (party.partner_id) is unambiguous in PostgREST;
      // 2-level nesting (event.party.partner_id) can be silently ignored on some versions.
      final nowStr = DateTime.now().toIso8601String();

      // Step 1: get future event IDs for this partner (same limit as getPartnerFutureEvents
      // to guarantee count and tab share identical event scope).
      final eventsData = await supabaseClient
          .from('events')
          .select('id, party:parties!inner(partner_id)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', nowStr)
          .order('start_time')
          .limit(500);

      final eventIds = eventsData.map((e) => e['id'] as String).toList();
      if (eventIds.isEmpty) return 0;

      // Step 2: count pending/pending_review applications for those events.
      final res = await supabaseClient
          .from('event_applications')
          .select('id')
          .inFilter('event_id', eventIds)
          .inFilter('status', ['pending', 'pending_review'])
          .count(CountOption.exact);

      return res.count;
    } on Exception catch (e, st) {
      Log.e('❌ [EventRepo] getPendingApplicationCount Error', e, st);
      return 0; // Fail safe
    }
  }

  /// Counts partner-owned applications waiting for refund completion.
  Future<int> getRequestedRefundCountForPartner(String partnerId) async {
    try {
      final res = await supabaseClient
          .from('event_applications')
          .select(
            'id, event:events!inner(id, party:parties!inner(partner_id))',
          )
          .eq('event.party.partner_id', partnerId)
          .eq('refund_status', 'requested')
          .count(CountOption.exact);

      return res.count;
    } on Exception catch (e, st) {
      Log.e('❌ [EventRepo] getRequestedRefundCountForPartner Error', e, st);
      rethrow;
    }
  }

  /// Fetches all upcoming events for a specific partner (via parties).
  /// Used in the partner detail page to show the partner's event list.
  Future<List<Event>> getEventsByPartnerId(String partnerId) async {
    Log.d('getEventsByPartnerId called | partnerId: $partnerId');
    try {
      final data = await supabaseClient
          .from('events')
          .select(
            '*, party:parties!inner(*, location:locations(*), '
            'partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets(*)',
          )
          .eq('party.partner_id', partnerId)
          .eq('status', 'scheduled')
          .gte('start_time', DateTime.now().toIso8601String())
          .order('start_time');
      final result = data.map(Event.fromJson).toList();

      Log.d('getEventsByPartnerId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getEventsByPartnerId Error', e, st);
      rethrow;
    }
  }

  // Fix #1215: 온보딩 표시 조건을 upcomingEvents가 아닌 전체 이벤트 존재 여부로 판단하기 위해 추가
  /// [Partner Dashboard]
  /// Returns true if the partner has ever created any event (past or future).
  /// Used to determine whether to show the onboarding guide — checking only
  /// upcoming events would incorrectly show onboarding after all events end.
  Future<bool> getHasAnyEvents(String partnerId) async {
    try {
      final res = await supabaseClient
          .from('events')
          .select('id, party:parties!inner(partner_id)')
          .eq('party.partner_id', partnerId)
          .limit(1)
          .count(CountOption.exact);
      return res.count > 0;
    } on Exception catch (e, st) {
      Log.e('❌ [EventRepo] getHasAnyEvents Error', e, st);
      rethrow;
    }
  }

  /// [Partner Dashboard]
  /// Fetches events scheduled for today for a specific partner.
  Future<List<Event>> getTodayEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', startOfDay)
          .lte('start_time', endOfDay)
          .order('start_time');
      return data.map((json) {
        return Event.fromJson(json);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getTodayEvents Error', e, st);
      rethrow;
    }
  }

  /// [Application Management]
  /// Fetches all future events for a partner (no upper date bound).
  /// Used in the application management tab to show all events with pending
  /// applications, regardless of how far in the future they are.
  // Fix #1597: 신청관리 탭의 getUpcomingEvents(7일) 제한으로 미래 이벤트 누락 방지
  Future<List<Event>> getPartnerFutureEvents(String partnerId) async {
    try {
      final nowStr = DateTime.now().toIso8601String();

      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', nowStr)
          .order('start_time')
          .limit(
            500,
          ); // Safety cap: prevents unbounded queries for prolific partners
      return data.map(Event.fromJson).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getPartnerFutureEvents Error', e, st);
      rethrow;
    }
  }

  /// [Partner Dashboard]
  /// Fetches events scheduled within the next 7 days for a specific partner.
  Future<List<Event>> getUpcomingEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final sevenDaysLater = now.add(const Duration(days: 7)).toIso8601String();

      // Fix #1823: exclude completed/cancelled events — events transition to
      // 'active' 30 min before start_time, so filtering to 'scheduled' only
      // would hide legitimate active events that haven't started yet.
      // Only hard-exclude terminal statuses (completed, cancelled).
      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .not('status', 'in', '(completed,cancelled)')
          .gte('start_time', nowStr)
          .lte('start_time', sevenDaysLater)
          .order('start_time');
      return data.map((json) {
        return Event.fromJson(json);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getUpcomingEvents Error', e, st);
      rethrow;
    }
  }

  /// [Partner Dashboard]
  /// Fetches events with start_time within the next 3 days for a specific
  /// partner. Used for "마감임박" (closing soon) display on dashboard.
  Future<List<Event>> getClosingSoonEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final threeDaysLater = now.add(const Duration(days: 3)).toIso8601String();

      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', nowStr)
          .lte('start_time', threeDaysLater)
          .order('start_time');
      return data.map((json) {
        return Event.fromJson(json);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getClosingSoonEvents Error', e, st);
      rethrow;
    }
  }
}
