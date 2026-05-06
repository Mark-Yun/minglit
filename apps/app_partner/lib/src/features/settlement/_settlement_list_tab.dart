part of 'settlement_page.dart';

sealed class _ListItem {
  const _ListItem();
}

class _MonthHeader extends _ListItem {
  const _MonthHeader(this.label);
  final String label;
}

class _CardItem extends _ListItem {
  const _CardItem(this.data);
  final SettlementItemDetail data;
}

class _ListTab extends ConsumerStatefulWidget {
  const _ListTab();

  @override
  ConsumerState<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends ConsumerState<_ListTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(settlementListControllerProvider.notifier).loadMore();
    }
  }

  List<_ListItem> _buildViewList(List<SettlementItemDetail> items) {
    final result = <_ListItem>[];
    String? lastMonth;
    for (final item in items) {
      final dt = item.createdAt;
      final label = '${dt.year}년 ${dt.month}월';
      if (label != lastMonth) {
        result.add(_MonthHeader(label));
        lastMonth = label;
      }
      result.add(_CardItem(item));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(settlementListControllerProvider);

    return Column(
      children: [
        const SizedBox(height: MinglitSpacing.small),
        StatusFilterChips(
          selectedStatus: listState.selectedStatus,
          onStatusChanged: (status) => ref
              .read(settlementListControllerProvider.notifier)
              .changeStatus(status),
        ),
        const SizedBox(height: MinglitSpacing.small),
        // Fix #127: 목록 로드 실패 시 일반 빈 상태 대신 오류 상태와 재시도 액션을 노출
        Expanded(
          child:
              listState.error != null &&
                  listState.items.isEmpty &&
                  !listState.isLoading
              ? MinglitEmptyState(
                  icon: Icons.error_outline,
                  title: '목록을 불러오지 못했습니다',
                  subtitle: '잠시 후 다시 시도해 주세요.',
                  actionLabel: '다시 시도',
                  onAction: () => ref
                      .read(settlementListControllerProvider.notifier)
                      .refresh(),
                )
              : listState.items.isEmpty && !listState.isLoading
              // Fix #997: 빈 정산 상태에 CTA 버튼 추가 — 필터 없을 때만 이벤트 생성 유도
              ? MinglitEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: '정산 항목이 없습니다',
                  subtitle: listState.selectedStatus != null
                      ? '다른 상태를 선택해 보세요.'
                      : '파티를 만들고 첫 이벤트를 시작해 보세요.',
                  actionLabel: listState.selectedStatus == null
                      ? '첫 이벤트 만들기'
                      : null,
                  // Fix #1680: 동일 패턴 — StatefulShellBranch cross-branch push 방지
                  // SettlementBranch → MoreBranch 경계에서 context.push()가 무음 실패하므로
                  // root GoRouter를 사용하는 coordinator에 위임한다.
                  onAction: listState.selectedStatus == null
                      ? () => ref
                            .read(settlementCoordinatorProvider.notifier)
                            .goToPartyCreate()
                      : null,
                )
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(settlementListControllerProvider.notifier)
                      .refresh(),
                  child: Builder(
                    builder: (context) {
                      final viewList = _buildViewList(listState.items);
                      return ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            viewList.length + (listState.isLoading ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= viewList.length) {
                            return const Padding(
                              padding: EdgeInsets.all(MinglitSpacing.medium),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final item = viewList[i];
                          return switch (item) {
                            _MonthHeader(:final label) => _MonthHeaderWidget(
                              label: label,
                            ),
                            _CardItem(:final data) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SettlementCard(
                                  item: data.toJson(),
                                  onTap: () => ref
                                      .read(
                                        settlementCoordinatorProvider.notifier,
                                      )
                                      .goToDetail(data.id),
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          };
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _MonthHeaderWidget extends StatelessWidget {
  const _MonthHeaderWidget({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.xsmall,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
