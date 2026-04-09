// feat #715: P6 빈/에러/로딩 상태 패턴 데모
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';

/// The four demo states for [DataStatesDemoPage].
enum DemoState {
  /// Populated data state.
  data,

  /// Loading state (inline, skeleton, full-screen variants).
  loading,

  /// Error state with retry affordance.
  error,

  /// Empty state with CTA.
  empty,
}

/// **P6 Data States Demo**
///
/// Showcases the three canonical loading variants, the standard empty-state
/// structure, and the standard error-state structure used across the app.
///
/// Use a [SegmentedButton] at the top to toggle between states.
class DataStatesDemoPage extends StatefulWidget {
  /// Creates a [DataStatesDemoPage].
  const DataStatesDemoPage({super.key});

  @override
  State<DataStatesDemoPage> createState() => _DataStatesDemoPageState();
}

class _DataStatesDemoPageState extends State<DataStatesDemoPage> {
  DemoState _state = DemoState.data;

  static const _mockItems = [
    '서울 한강공원 피크닉',
    '홍대 카페 모임',
    '강남 북클럽',
    '이태원 언어교환',
    '성수 플리마켓',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('P6 · 데이터 상태 패턴')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
              vertical: MinglitSpacing.sm,
            ),
            child: _StateToggle(
              current: _state,
              onChanged: (s) => setState(() => _state = s),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: MinglitAnimation.fast,
              child: KeyedSubtree(
                key: ValueKey(_state),
                child: _buildBody(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return switch (_state) {
      DemoState.data => const _DataContent(items: _mockItems),
      DemoState.loading => const _LoadingContent(),
      DemoState.error => _ErrorContent(
        onRetry: () => setState(() => _state = DemoState.data),
      ),
      DemoState.empty => _EmptyContent(
        onAdd: () => setState(() => _state = DemoState.data),
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// State toggle
// ---------------------------------------------------------------------------

class _StateToggle extends StatelessWidget {
  const _StateToggle({required this.current, required this.onChanged});

  final DemoState current;
  final ValueChanged<DemoState> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DemoState>(
      segments: const [
        ButtonSegment(value: DemoState.data, label: Text('데이터')),
        ButtonSegment(value: DemoState.loading, label: Text('로딩')),
        ButtonSegment(value: DemoState.error, label: Text('오류')),
        ButtonSegment(value: DemoState.empty, label: Text('빈 목록')),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity(horizontal: -2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data content
// ---------------------------------------------------------------------------

class _DataContent extends StatelessWidget {
  const _DataContent({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: MinglitSpacing.small),
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: MinglitColors.primary.withValues(
                alpha: MinglitOpacity.skeletonBase,
              ),
              child: Text(
                '${index + 1}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: MinglitColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(items[index]),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: MinglitIconSize.xsmall,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading content (3 variants)
// ---------------------------------------------------------------------------

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant 1 – inline spinner
          _SectionLabel(label: '① 인라인 스피너', theme: theme),
          const SizedBox(height: MinglitSpacing.small),
          const Center(
            child: MinglitCircularProgressIndicator(
              color: MinglitColors.primary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Variant 2 – skeleton list
          _SectionLabel(label: '② 스켈레톤 카드 목록', theme: theme),
          const SizedBox(height: MinglitSpacing.small),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
              child: Row(
                children: [
                  MinglitSkeleton(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MinglitSkeleton(height: 14),
                        SizedBox(height: MinglitSpacing.xsmall),
                        MinglitSkeleton(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Variant 3 – full-screen overlay note
          _SectionLabel(label: '③ 전체화면 오버레이', theme: theme),
          const SizedBox(height: MinglitSpacing.small),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              color: MinglitColors.surface,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
              border: Border.all(
                color: MinglitColors.textSecondary.withValues(
                  alpha: MinglitOpacity.subtle,
                ),
              ),
            ),
            child: Text(
              'MinglitGlobalLoadingOverlay — MaterialApp.builder에서 '
              'child를 감싸서 사용합니다.\n'
              '전체화면을 블로킹하는 모달 오버레이입니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: MinglitColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: MinglitIconSize.xlarge, // 32px — UX review confirmed
              color: MinglitColors.textSecondary,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '등록된 항목이 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: MinglitColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '아직 항목이 없어요. 새 항목을 추가해 보세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MinglitColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('항목 추가'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: MinglitIconSize.xlarge, // 32px — UX review confirmed
              color: MinglitColors.error,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '오류가 발생했습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: MinglitColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '데이터를 불러오지 못했습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: MinglitColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.large),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
