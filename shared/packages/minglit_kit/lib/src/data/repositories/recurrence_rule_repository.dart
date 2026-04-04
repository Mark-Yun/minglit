import 'dart:convert';

import 'package:minglit_kit/src/data/models/recurrence_rule.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'recurrence_rule_repository.g.dart';

/// Provides the [RecurrenceRuleRepository].
@Riverpod(keepAlive: true)
RecurrenceRuleRepository recurrenceRuleRepository(Ref ref) {
  return RecurrenceRuleRepository(Supabase.instance.client);
}

/// Repository for recurrence rule data and lifecycle management.
///
/// Wraps the `recurrence-rules` Edge Function for mutating operations
/// and performs direct table queries for reads.
class RecurrenceRuleRepository {
  /// Creates a [RecurrenceRuleRepository] with a Supabase client.
  RecurrenceRuleRepository(this._client);
  final SupabaseClient _client;

  static const _efName = 'recurrence-rules';

  static const _select =
      'id, party_id, pattern, days_of_week, month_day, '
      'start_time, end_time, end_date, status, last_generated_date, '
      'created_at, updated_at';

  /// Creates a new recurrence rule for the given party and starts generating
  /// events immediately.
  ///
  /// For [pattern] `weekly` or `biweekly`, [daysOfWeek] must be non-empty.
  /// For [pattern] `monthly`, [monthDay] must be provided (1–31).
  ///
  /// Returns the newly created [RecurrenceRule].
  Future<RecurrenceRule> create({
    required String partyId,
    required RecurrencePattern pattern,
    required List<int> daysOfWeek,
    required String startTime,
    required String endTime,
    int? monthDay,
    String? endDate,
  }) async {
    final body = <String, dynamic>{
      'action': 'create',
      'party_id': partyId,
      'pattern': pattern.name,
      'days_of_week': daysOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    };
    if (monthDay != null) body['month_day'] = monthDay;
    if (endDate != null) body['end_date'] = endDate;

    final response = await _client.functions.invoke(_efName, body: body);
    _ensureSuccess(response);

    final data = _decodeResponse(response);
    final rawId = data['rule_id'];
    if (rawId is! String || rawId.isEmpty) {
      throw FunctionException(
        status: 500,
        details: jsonEncode(data),
        reasonPhrase: 'Missing rule_id in create response',
      );
    }

    final rule = await getById(rawId);
    if (rule == null) {
      throw FunctionException(
        status: 500,
        details: 'Created rule $rawId but failed to load from recurrence_rules',
        reasonPhrase: 'Post-create read failed',
      );
    }
    return rule;
  }

  /// Updates mutable fields of an existing active or paused rule.
  ///
  /// At least one field must be provided. Cancelled rules cannot be updated.
  Future<void> update(
    String ruleId, {
    RecurrencePattern? pattern,
    List<int>? daysOfWeek,
    int? monthDay,
    String? startTime,
    String? endTime,
    String? endDate,
  }) async {
    final body = <String, dynamic>{
      'action': 'update',
      'rule_id': ruleId,
    };
    if (pattern != null) body['pattern'] = pattern.name;
    if (daysOfWeek != null) body['days_of_week'] = daysOfWeek;
    if (monthDay != null) body['month_day'] = monthDay;
    if (startTime != null) body['start_time'] = startTime;
    if (endTime != null) body['end_time'] = endTime;
    if (endDate != null) body['end_date'] = endDate;

    final response = await _client.functions.invoke(_efName, body: body);
    _ensureSuccess(response);
  }

  /// Pauses the rule — no new events will be generated until resumed.
  Future<void> pause(String ruleId) async {
    final response = await _client.functions.invoke(
      _efName,
      body: {'action': 'pause', 'rule_id': ruleId},
    );
    _ensureSuccess(response);
  }

  /// Resumes a paused rule and immediately generates any missed events.
  Future<void> resume(String ruleId) async {
    final response = await _client.functions.invoke(
      _efName,
      body: {'action': 'resume', 'rule_id': ruleId},
    );
    _ensureSuccess(response);
  }

  /// Cancels the rule permanently. Existing generated events are preserved.
  Future<void> cancel(String ruleId) async {
    final response = await _client.functions.invoke(
      _efName,
      body: {'action': 'cancel', 'rule_id': ruleId},
    );
    _ensureSuccess(response);
  }

  /// Returns the active or paused recurrence rule for the given party,
  /// or `null` if none exists.
  Future<RecurrenceRule?> getByPartyId(String partyId) async {
    final row = await _client
        .from('recurrence_rules')
        .select(_select)
        .eq('party_id', partyId)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return RecurrenceRule.fromJson(row);
  }

  /// Returns the recurrence rule with the given [id], or `null` if not found.
  Future<RecurrenceRule?> getById(String id) async {
    final row = await _client
        .from('recurrence_rules')
        .select(_select)
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return RecurrenceRule.fromJson(row);
  }

  void _ensureSuccess(FunctionResponse response) {
    if (response.status != 200) {
      final body = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      throw FunctionException(
        status: response.status,
        details: body,
        reasonPhrase: 'Edge function error',
      );
    }
  }

  Map<String, dynamic> _decodeResponse(FunctionResponse response) {
    return response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
  }
}
