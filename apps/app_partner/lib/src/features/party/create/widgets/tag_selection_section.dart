import 'dart:async';

import 'package:app_partner/src/features/party/create/logic/tag_selection_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 파티 생성 위저드 Step 1의 태그 선택 섹션.
///
/// - 인기 태그 퀵 선택 (featuredTagsProvider 상위 10개)
/// - 태그 검색 자동완성 (tagSearchProvider, 500ms 디바운스)
/// - 선택된 태그 InputChip 리스트 (삭제 가능)
/// - 5개 초과 시 추가 선택 비활성
class TagSelectionSection extends ConsumerStatefulWidget {
  const TagSelectionSection({super.key});

  @override
  ConsumerState<TagSelectionSection> createState() =>
      _TagSelectionSectionState();
}

class _TagSelectionSectionState extends ConsumerState<TagSelectionSection> {
  final TextEditingController _searchController = TextEditingController();

  // 500ms 디바운스 처리를 위한 타이머 및 검색어 상태
  Timer? _debounceTimer;
  String _searchQuery = '';

  // wizard state에서 마지막으로 동기화한 tagIds — 중복 sync 방지용
  List<String> _lastSyncedTagIds = const [];

  @override
  void initState() {
    super.initState();
    // 편집 모드: wizard state에 미리 로드된 tagIds가 있으면
    // TagSelectionController를 초기화한다 (Tag 객체는 TagRepository로 조회).
    // addPostFrameCallback으로 첫 프레임 이후에 읽어 ref가 준비된 상태에서 실행.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromWizardTagIds(
        ref.read(partyCreateWizardControllerProvider).tagIds,
      );
    });
  }

  /// wizard state의 tagIds가 외부(예: edit load)로 인해 변경될 때 동기화한다.
  ///
  /// build()에서 ref.listen으로 호출된다.
  Future<void> _syncFromWizardTagIds(List<String> tagIds) async {
    if (!mounted) return;
    // TagSelectionController가 이미 같은 목록을 보유하면 skip
    if (tagIds.isEmpty) return;
    if (_lastSyncedTagIds.length == tagIds.length &&
        _lastSyncedTagIds.every(tagIds.contains)) {
      return;
    }
    _lastSyncedTagIds = List.unmodifiable(tagIds);

    final tagRepo = ref.read(tagRepositoryProvider);
    final tags = await tagRepo.getTagsByIds(tagIds);
    if (!mounted) return;
    ref.read(tagSelectionControllerProvider.notifier).setTags(tags);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      setState(() => _searchQuery = '');
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedTags = ref.watch(tagSelectionControllerProvider);
    final controller = ref.read(tagSelectionControllerProvider.notifier);
    final isMaxReached = controller.isMaxReached;

    // 태그 선택 변경 시 위저드 컨트롤러의 tagIds를 동기화한다
    ref.listen<List<Tag>>(tagSelectionControllerProvider, (_, next) {
      ref
          .read(partyCreateWizardControllerProvider.notifier)
          .updateTagIds(next.map((t) => t.id).toList());
    });

    // 편집 모드에서 wizard tagIds가 비동기로 로드되면 TagSelectionController를 갱신한다
    ref.listen<PartyCreateWizardState>(
      partyCreateWizardControllerProvider,
      (previous, next) {
        if (previous?.tagIds != next.tagIds) {
          _syncFromWizardTagIds(next.tagIds);
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Text(
          '태그 (최대 5개)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),

        // 태그 검색 입력
        _TagSearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          isDisabled: isMaxReached,
        ),
        const SizedBox(height: MinglitSpacing.medium),

        // 검색 결과 또는 인기 태그 퀵 선택
        if (_searchQuery.isNotEmpty)
          _TagSearchResults(
            query: _searchQuery,
            selectedTags: selectedTags,
            onTagSelected: (tag) {
              controller.addTag(tag);
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
        else
          _FeaturedTagsQuickSelect(
            selectedTags: selectedTags,
            onTagSelected: controller.addTag,
          ),

        // 선택된 태그 목록
        if (selectedTags.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          _SelectedTagsChips(
            tags: selectedTags,
            onRemove: controller.removeTag,
          ),
        ],
      ],
    );
  }
}

// --- 내부 위젯 ---

class _TagSearchField extends StatelessWidget {
  const _TagSearchField({
    required this.controller,
    required this.onChanged,
    required this.isDisabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: !isDisabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: isDisabled ? '태그 5개가 선택되었습니다' : '태그 검색...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

/// 검색 결과 태그 목록 (tagSearchProvider 사용, 500ms 디바운스).
class _TagSearchResults extends ConsumerWidget {
  const _TagSearchResults({
    required this.query,
    required this.selectedTags,
    required this.onTagSelected,
  });

  final String query;
  final List<Tag> selectedTags;
  final ValueChanged<Tag> onTagSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // tagSearchProvider는 dev-2가 구현 — query 기준 500ms 디바운스 적용
    final searchAsync = ref.watch(tagSearchProvider(query));

    return searchAsync.when(
      loading: () => const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) {
          return Text(
            '일치하는 태그가 없어요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: tags.map((tag) {
            final isSelected = selectedTags.any((t) => t.id == tag.id);
            return FilterChip(
              label: Text('#${tag.name}'),
              selected: isSelected,
              onSelected: isSelected ? null : (_) => onTagSelected(tag),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 인기 태그 퀵 선택 (featuredTagsProvider 상위 10개).
class _FeaturedTagsQuickSelect extends ConsumerWidget {
  const _FeaturedTagsQuickSelect({
    required this.selectedTags,
    required this.onTagSelected,
  });

  final List<Tag> selectedTags;
  final ValueChanged<Tag> onTagSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredTagsProvider);
    final controller = ref.read(tagSelectionControllerProvider.notifier);

    return featuredAsync.when(
      loading: () => const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (tags) {
        final topTen = tags.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인기 태그',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Wrap(
              spacing: MinglitSpacing.small,
              runSpacing: MinglitSpacing.small,
              children: topTen.map((tag) {
                final isSelected = selectedTags.any((t) => t.id == tag.id);
                return FilterChip(
                  label: Text('#${tag.name}'),
                  selected: isSelected,
                  onSelected: controller.isMaxReached && !isSelected
                      ? null
                      : (selected) {
                          if (selected) {
                            onTagSelected(tag);
                          } else {
                            controller.removeTag(tag.id);
                          }
                        },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

/// 선택된 태그 InputChip 목록 (삭제 가능).
class _SelectedTagsChips extends StatelessWidget {
  const _SelectedTagsChips({
    required this.tags,
    required this.onRemove,
  });

  final List<Tag> tags;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 태그',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: tags
              .map(
                (tag) => InputChip(
                  label: Text('#${tag.name}'),
                  onDeleted: () => onRemove(tag.id),
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
