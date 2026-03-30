import 'package:minglit_kit/src/data/models/deletion_status.dart';
import 'package:minglit_kit/src/data/models/withdrawal_reason.dart';
import 'package:minglit_kit/src/data/repositories/account_repository.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_deletion_controller.g.dart';

/// Manages shared account deletion state for the signed-in user.
@riverpod
class AccountDeletionController extends _$AccountDeletionController {
  @override
  FutureOr<DeletionStatus?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    final repository = ref.watch(accountRepositoryProvider);
    return repository.getDeletionStatus();
  }

  /// Reloads the deletion status from the backend.
  Future<DeletionStatus?> checkStatus() async {
    if (state.isLoading) return state.value;

    state = const AsyncLoading();
    try {
      final nextStatus = await ref
          .read(accountRepositoryProvider)
          .getDeletionStatus();
      state = AsyncData(nextStatus);
      return nextStatus;
    } on Object catch (error, stackTrace) {
      state = AsyncError(MinglitException.from(error, stackTrace), stackTrace);
      return state.value;
    }
  }

  /// Requests account deletion with an optional anonymous [reason].
  Future<DeletionStatus?> requestDeletion({WithdrawalReason? reason}) async {
    if (state.isLoading) return state.value;

    state = const AsyncLoading();
    try {
      final nextStatus = await ref
          .read(accountRepositoryProvider)
          .deleteAccount(reason);
      state = AsyncData(nextStatus);
      return nextStatus;
    } on Object catch (error, stackTrace) {
      state = AsyncError(MinglitException.from(error, stackTrace), stackTrace);
      return state.value;
    }
  }

  /// Cancels a pending deletion and reloads the latest status.
  Future<DeletionStatus?> cancelDeletion() async {
    if (state.isLoading) return state.value;

    state = const AsyncLoading();
    final repository = ref.read(accountRepositoryProvider);
    try {
      await repository.cancelDeletion();
      final nextStatus = await repository.getDeletionStatus();
      state = AsyncData(nextStatus);
      return nextStatus;
    } on Object catch (error, stackTrace) {
      state = AsyncError(MinglitException.from(error, stackTrace), stackTrace);
      return state.value;
    }
  }

  /// Reauthenticates the signed-in user before destructive actions.
  Future<void> reauthenticate(String? password) async {
    final previous = state;
    try {
      await ref.read(accountRepositoryProvider).reauthenticate(password);
    } on Object catch (error, stackTrace) {
      state = AsyncError(MinglitException.from(error, stackTrace), stackTrace);
      rethrow;
    }

    state = previous;
  }
}
