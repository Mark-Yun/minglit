import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurrence_management_controller.g.dart';

/// State for recurrence management operations.
@riverpod
class RecurrenceManagementController extends _$RecurrenceManagementController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  /// Pauses the active recurrence rule.
  Future<void> pause(String ruleId) async {
    state = const AsyncLoading();
    try {
      await ref.read(recurrenceRuleRepositoryProvider).pause(ruleId);
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Resumes a paused recurrence rule and immediately generates missed events.
  Future<void> resume(String ruleId) async {
    state = const AsyncLoading();
    try {
      await ref.read(recurrenceRuleRepositoryProvider).resume(ruleId);
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Permanently cancels the recurrence rule.
  Future<void> cancel(String ruleId) async {
    state = const AsyncLoading();
    try {
      await ref.read(recurrenceRuleRepositoryProvider).cancel(ruleId);
      state = const AsyncData(null);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Fetches the active-or-paused recurrence rule for a party.
/// Returns null if no rule exists.
@riverpod
Future<RecurrenceRule?> partyRecurrenceRule(Ref ref, String partyId) {
  return ref.watch(recurrenceRuleRepositoryProvider).getByPartyId(partyId);
}
