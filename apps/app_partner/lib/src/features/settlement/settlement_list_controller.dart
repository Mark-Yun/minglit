import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settlement_list_controller.freezed.dart';
part 'settlement_list_controller.g.dart';

@freezed
abstract class SettlementListState with _$SettlementListState {
  const factory SettlementListState({
    @Default([]) List<SettlementItemDetail> items,
    @Default(null) String? selectedStatus,
    @Default(false) bool isLoading,
    @Default(true) bool hasMore,
    @Default(null) String? error,
  }) = _SettlementListState;
}

@riverpod
class SettlementListController extends _$SettlementListController {
  static const _pageSize = 20;
  int _currentGeneration = 0;

  @override
  SettlementListState build() {
    unawaited(Future.microtask(loadMore));
    return const SettlementListState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final generation = _currentGeneration;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final repo = ref.read(settlementRepositoryProvider);
      final newItems = await repo.getSettlementItems(
        partnerId: partner.id,
        status: state.selectedStatus,
        offset: state.items.length,
      );
      // Race condition guard: discard stale responses
      if (generation != _currentGeneration) return;
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...newItems],
        hasMore: newItems.length == _pageSize,
      );
    } on Exception catch (e, st) {
      if (generation != _currentGeneration) return;
      Log.e('SettlementListController loadMore error', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void changeStatus(String? status) {
    _currentGeneration++;
    state = state.copyWith(
      selectedStatus: status,
      items: [],
      hasMore: true,
      error: null,
    );
    unawaited(loadMore());
  }

  Future<void> refresh() async {
    _currentGeneration++;
    state = state.copyWith(
      items: [],
      hasMore: true,
      error: null,
    );
    await loadMore();
  }
}
