import 'dart:async';

import 'package:app_user/src/features/search/logic/search_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Full-page search screen.
/// - AppBar with inline search TextField (500ms debounce)
/// - Results via searchResultsProvider
/// - Clears query on dispose
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Fix #226: Clear stale query on entry instead of dispose.
    // Clearing in dispose() triggers Riverpod state changes during widget
    // teardown, which is unsafe in Riverpod ≥3.
    Future.microtask(
      () => ref.read(searchQueryProvider.notifier).clear(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).update(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    // Fix #634: event_coordinator 직접 참조 → search_coordinator 전환
    final searchCoordinator = ref.read(searchCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '이벤트 검색',
            border: InputBorder.none,
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, _) => value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).clear();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (query.isEmpty) {
            // Fix #997: 검색 초기 상태에 키워드 제안 추가
            const suggestedKeywords = ['파티', '클래스', '스포츠', '아트'];
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.xlarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    Text(
                      '검색어를 입력하세요',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      '이런 키워드는 어때요?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    Wrap(
                      spacing: MinglitSpacing.small,
                      runSpacing: MinglitSpacing.xsmall,
                      alignment: WrapAlignment.center,
                      children: suggestedKeywords
                          .map(
                            (keyword) => ActionChip(
                              label: Text(keyword),
                              onPressed: () {
                                _debounce?.cancel();
                                _controller.text = keyword;
                                _controller.selection = TextSelection.collapsed(
                                  offset: keyword.length,
                                );
                                ref
                                    .read(searchQueryProvider.notifier)
                                    .update(keyword);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          }

          return MinglitAsyncValueWidget(
            value: searchAsync,
            data: (events) {
              if (events.isEmpty) {
                // Fix #997: 검색 결과 없음 상태 메시지 개선 — 아이콘 + 안내 문구 추가
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.xlarge),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: MinglitSpacing.medium),
                        Text(
                          '검색 결과가 없습니다.',
                          style:
                              Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        Text(
                          '다른 키워드로 시도해보세요.',
                          style:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.medium,
                ),
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: MinglitSpacing.small),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return MinglitEventCard(
                    event: event,
                    onTap: () => searchCoordinator.pushEventDetail(event.id),
                  );
                },
              );
            },
            loading: () => const Center(
              child: MinglitCircularProgressIndicator(),
            ),
            error: (e, _) => const Center(
              child: Text('검색 중 오류가 발생했습니다'),
            ),
          );
        },
      ),
    );
  }
}
