import 'dart:async';

import 'package:app_user/src/features/tag/logic/tag_event_list_controller.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Displays the paginated list of events for a specific tag.
class TagEventListPage extends ConsumerStatefulWidget {
  const TagEventListPage({
    required this.tagId,
    required this.tagName,
    super.key,
  });

  final String tagId;
  final String tagName;

  @override
  ConsumerState<TagEventListPage> createState() => _TagEventListPageState();
}

class _TagEventListPageState extends ConsumerState<TagEventListPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(
        ref
            .read(tagEventListControllerProvider(widget.tagId).notifier)
            .loadMore(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(tagEventListControllerProvider(widget.tagId));

    return Scaffold(
      appBar: AppBar(
        title: Text('#${widget.tagName}'),
        centerTitle: true,
      ),
      body: stateAsync.when(
        data: (state) {
          if (state.events.isEmpty && !state.hasMore) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '아직 이 태그의 이벤트가 없어요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  // Fix #1136: context.pop()은 이전 스택이 없으면 홈으로 이동하지 않으므로
                  // HomeRoute로 명시적 이동
                  TextButton(
                    onPressed: () => const HomeRoute().go(context),
                    child: const Text('홈으로 돌아가기'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            controller: _scrollController,
            itemCount: state.events.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: MinglitSpacing.small),
            itemBuilder: (context, index) {
              if (index >= state.events.length) {
                return const Padding(
                  padding: EdgeInsets.all(MinglitSpacing.medium),
                  child: Center(child: MinglitCircularProgressIndicator()),
                );
              }
              final event = state.events[index];
              return MinglitEventCard(
                event: event,
                // Fix #1136: Coordinator 패턴 — 위젯에서 직접 GoRouter 호출 금지
                onTap: () => ref
                    .read(eventCoordinatorProvider)
                    .goToEventDetail(event.id),
              );
            },
          );
        },
        loading: () => const Center(child: MinglitCircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이벤트를 불러오지 못했습니다'),
              const SizedBox(height: MinglitSpacing.small),
              TextButton(
                onPressed: () => ref.invalidate(
                  tagEventListControllerProvider(widget.tagId),
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
