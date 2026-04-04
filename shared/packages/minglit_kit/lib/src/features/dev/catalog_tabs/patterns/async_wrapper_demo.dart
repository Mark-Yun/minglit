import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';

/// Demo states for the async wrapper interactive demo.
enum AsyncDemoState {
  /// Shows shimmer/skeleton loading UI.
  loading,

  /// Shows error widget with retry button.
  error,

  /// Shows data list.
  data,
}

/// Mock data item for the data-state demo list.
class _MockItem {
  const _MockItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const _mockItems = [
  _MockItem(title: '첫 번째 항목', subtitle: '상세 설명 텍스트입니다.'),
  _MockItem(title: '두 번째 항목', subtitle: '다양한 상태를 시연합니다.'),
  _MockItem(title: '세 번째 항목', subtitle: 'AsyncValue를 사용하세요.'),
];

/// **P7 Async 래퍼 패턴 데모**
///
/// [MinglitAsyncValueWidget]을 사용해 [AsyncValue]의 세 가지 상태
/// (loading / error / data)를 처리하는 패턴을 보여줍니다.
///
/// 상단의 [SegmentedButton]으로 상태를 전환하고,
/// 하단의 Do / Don't 섹션에서 올바른 사용법과 지양할 패턴을 확인할 수 있습니다.
class AsyncWrapperDemoPage extends StatefulWidget {
  /// Creates the async wrapper pattern demo page.
  const AsyncWrapperDemoPage({super.key});

  @override
  State<AsyncWrapperDemoPage> createState() => _AsyncWrapperDemoPageState();
}

class _AsyncWrapperDemoPageState extends State<AsyncWrapperDemoPage> {
  AsyncDemoState _selectedState = AsyncDemoState.data;

  AsyncValue<List<_MockItem>> get _asyncValue {
    return switch (_selectedState) {
      AsyncDemoState.loading => const AsyncValue.loading(),
      AsyncDemoState.error => AsyncValue.error(
          Exception('데이터를 불러오지 못했습니다.'),
          StackTrace.empty,
        ),
      AsyncDemoState.data => const AsyncValue.data(_mockItems),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('P7 Async 래퍼 패턴')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StateToggle(
              selected: _selectedState,
              onChanged: (state) => setState(() => _selectedState = state),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            _DemoPreview(asyncValue: _asyncValue),
            const SizedBox(height: MinglitSpacing.large),
            _DoSection(theme: theme),
            const SizedBox(height: MinglitSpacing.medium),
            _DontSection(theme: theme),
            const SizedBox(height: MinglitSpacing.large),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// State Toggle
// ---------------------------------------------------------------------------

class _StateToggle extends StatelessWidget {
  const _StateToggle({required this.selected, required this.onChanged});

  final AsyncDemoState selected;
  final ValueChanged<AsyncDemoState> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<AsyncDemoState>(
        segments: const [
          ButtonSegment(
            value: AsyncDemoState.loading,
            label: Text('loading'),
            icon: Icon(Icons.hourglass_empty),
          ),
          ButtonSegment(
            value: AsyncDemoState.error,
            label: Text('error'),
            icon: Icon(Icons.error_outline),
          ),
          ButtonSegment(
            value: AsyncDemoState.data,
            label: Text('data'),
            icon: Icon(Icons.check_circle_outline),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (set) {
          if (set.isNotEmpty) onChanged(set.first);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo Preview
// ---------------------------------------------------------------------------

class _DemoPreview extends StatelessWidget {
  const _DemoPreview({required this.asyncValue});

  final AsyncValue<List<_MockItem>> asyncValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: MinglitColors.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: MinglitAsyncValueWidget<List<_MockItem>>(
          value: asyncValue,
          loading: _buildSkeleton,
          error: (err, _) => _ErrorView(onRetry: () {}),
          data: (items) => _DataList(items: items),
        ),
      ),
    );
  }

  Widget _buildSkeleton() => const _SkeletonList();
}

// ---------------------------------------------------------------------------
// Skeleton List
// ---------------------------------------------------------------------------

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        children: List.generate(3, (i) => _SkeletonRow(key: ValueKey(i))),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
      child: Row(
        children: [
          const MinglitSkeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(
              Radius.circular(MinglitRadius.small),
            ),
          ),
          const SizedBox(width: MinglitSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MinglitSkeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: MinglitSpacing.xsmall),
                MinglitSkeleton(
                  width: 140,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error View
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: MinglitColors.error,
            size: MinglitIconSize.xlarge,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '오류가 발생했습니다.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: MinglitColors.textPrimary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '데이터를 불러오지 못했습니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MinglitColors.textSecondary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data List
// ---------------------------------------------------------------------------

class _DataList extends StatelessWidget {
  const _DataList({required this.items});

  final List<_MockItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: MinglitSpacing.small),
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius:
                    BorderRadius.circular(MinglitRadius.small),
              ),
              child: Icon(
                Icons.article_outlined,
                size: MinglitIconSize.small,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MinglitColors.textPrimary,
                    ),
                  ),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MinglitColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Do / Don't sections
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  const _CodeSnippet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        // ignore: minglit_no_hardcoded_colors -- code snippet background is intentionally dark
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Text(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          // ignore: minglit_no_hardcoded_colors -- code text is intentionally light-on-dark
          color: Color(0xFFD4D4D4),
          height: 1.6,
        ),
      ),
    );
  }
}

class _DoSection extends StatelessWidget {
  const _DoSection({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          label: 'Do — MinglitAsyncValueWidget 사용',
          color: MinglitColors.success,
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'AsyncValue 상태를 한 곳에서 처리하고, 로딩/에러 UI를 일관되게 유지합니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: MinglitColors.textSecondary,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        const _CodeSnippet(
          code: 'MinglitAsyncValueWidget<List<Item>>(\n'
              '  value: ref.watch(itemsProvider),\n'
              '  data: (items) => ItemList(items: items),\n'
              '  // loading/error는 기본 UI가 자동 처리됩니다.\n'
              ')',
        ),
      ],
    );
  }
}

class _DontSection extends StatelessWidget {
  const _DontSection({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          label: "Don't — 수동 setState + _isLoading",
          color: MinglitColors.error,
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          '로딩/에러 상태를 직접 관리하면 중복 코드가 늘어나고 '
          '일관성을 유지하기 어렵습니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: MinglitColors.textSecondary,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        const _CodeSnippet(
          code: '// ❌ 피하세요\n'
              'bool _isLoading = false;\n'
              'String? _error;\n'
              'List<Item>? _items;\n\n'
              'Future<void> _load() async {\n'
              '  setState(() => _isLoading = true);\n'
              '  try {\n'
              '    _items = await repo.fetchItems();\n'
              '  } catch (e) {\n'
              '    _error = e.toString();\n'
              '  } finally {\n'
              '    setState(() => _isLoading = false);\n'
              '  }\n'
              '}',
        ),
      ],
    );
  }
}
