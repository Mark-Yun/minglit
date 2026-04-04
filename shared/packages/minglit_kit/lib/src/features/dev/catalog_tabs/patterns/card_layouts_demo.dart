import 'package:flutter/material.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/detail_page_demo.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_empty_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_error_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_key_value_row.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';

/// P4 — Card Layouts Demo.
///
/// Demonstrates 5 card variants: Image, Transaction, Info, Stats, Selectable.
/// Includes [DemoState] toggle (data / loading / error / empty).
///
/// Launch via [Navigator.push]:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const CardLayoutsDemo()));
/// ```
class CardLayoutsDemo extends StatefulWidget {
  /// Creates a [CardLayoutsDemo].
  const CardLayoutsDemo({super.key});

  @override
  State<CardLayoutsDemo> createState() => _CardLayoutsDemoState();
}

class _CardLayoutsDemoState extends State<CardLayoutsDemo> {
  DemoState _state = DemoState.data;
  int _selectedCard = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P4 — 카드 레이아웃')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: SegmentedButton<DemoState>(
              segments: const [
                ButtonSegment(value: DemoState.data, label: Text('Data')),
                ButtonSegment(
                  value: DemoState.loading,
                  label: Text('Loading'),
                ),
                ButtonSegment(value: DemoState.error, label: Text('Error')),
                ButtonSegment(value: DemoState.empty, label: Text('Empty')),
              ],
              selected: {_state},
              onSelectionChanged: (s) => setState(() => _state = s.first),
            ),
          ),
          Expanded(child: _buildPreview()),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return switch (_state) {
      DemoState.loading => const _CardLayoutsLoading(),
      DemoState.error => _CardLayoutsError(
        onRetry: () => setState(() => _state = DemoState.data),
      ),
      DemoState.empty => const _CardLayoutsEmpty(),
      DemoState.data => _CardLayoutsData(
        selectedCard: _selectedCard,
        onSelectCard: (index) => setState(() {
          _selectedCard = _selectedCard == index ? -1 : index;
        }),
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Data state
// ---------------------------------------------------------------------------

class _CardLayoutsData extends StatelessWidget {
  const _CardLayoutsData({
    required this.selectedCard,
    required this.onSelectCard,
  });

  final int selectedCard;
  final ValueChanged<int> onSelectCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        _CardVariantLabel(label: 'Image Card', theme: theme),
        const SizedBox(height: MinglitSpacing.small),
        const _ImageCard(),
        const SizedBox(height: MinglitSpacing.medium),
        _CardVariantLabel(label: 'Transaction Card', theme: theme),
        const SizedBox(height: MinglitSpacing.small),
        const _TransactionCard(),
        const SizedBox(height: MinglitSpacing.medium),
        _CardVariantLabel(label: 'Info Card', theme: theme),
        const SizedBox(height: MinglitSpacing.small),
        const _InfoCard(),
        const SizedBox(height: MinglitSpacing.medium),
        _CardVariantLabel(label: 'Stats Card', theme: theme),
        const SizedBox(height: MinglitSpacing.small),
        const _StatsCard(),
        const SizedBox(height: MinglitSpacing.medium),
        _CardVariantLabel(label: 'Selectable Card', theme: theme),
        const SizedBox(height: MinglitSpacing.small),
        _SelectableCard(
          selected: selectedCard == 0,
          onTap: () => onSelectCard(0),
        ),
      ],
    );
  }
}

class _CardVariantLabel extends StatelessWidget {
  const _CardVariantLabel({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card variants
// ---------------------------------------------------------------------------

/// Image card variant with a colored image placeholder, title, and subtitle.
class _ImageCard extends StatelessWidget {
  const _ImageCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MinglitContentCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MinglitRadius.card),
            ),
            child: Container(
              width: double.infinity,
              height: 120,
              color: MinglitColors.primary.withValues(alpha: 0.15),
              child: Icon(
                Icons.image_outlined,
                size: MinglitIconSize.xlarge,
                color: MinglitColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '재즈 이브닝 in 성수',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  '재즈 음악을 사랑하는 분들을 위한 소셜 이벤트',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction card variant with icon, title, amount, and date.
class _TransactionCard extends StatelessWidget {
  const _TransactionCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MinglitContentCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MinglitColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MinglitRadius.small),
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: MinglitColors.primary,
              size: MinglitIconSize.small,
            ),
          ),
          const SizedBox(width: MinglitSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이벤트 참가비', style: theme.textTheme.bodyMedium),
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  '2026.04.15',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-₩15,000',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info card variant with key-value rows.
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return const MinglitContentCard(
      child: Column(
        children: [
          MinglitKeyValueRow(label: '카테고리', value: '음악'),
          MinglitKeyValueRow(label: '주최자', value: '밍글릿 팀'),
          MinglitKeyValueRow(
            label: '참가비',
            value: '₩15,000',
            bold: true,
          ),
          MinglitKeyValueRow(label: '정원', value: '20명'),
        ],
      ),
    );
  }
}

/// Stats card variant with 3 stat numbers in a row.
class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return MinglitContentCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatItem(label: '참여자', value: '12'),
          _StatItem(label: '이벤트', value: '5'),
          _StatItem(label: '후기', value: '38'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: MinglitColors.primary,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xsmall),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Selectable card variant that toggles a highlighted border on tap.
class _SelectableCard extends StatelessWidget {
  const _SelectableCard({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MinglitContentCard(
      highlighted: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: MinglitSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('브런치 네트워킹', style: theme.textTheme.titleSmall),
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  '탭하여 선택/해제',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
// Loading state
// ---------------------------------------------------------------------------

class _CardLayoutsLoading extends StatelessWidget {
  const _CardLayoutsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        const MinglitSkeleton(width: 80, height: 14),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 160,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitSkeleton(width: 100, height: 14),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 72,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitSkeleton(width: 80, height: 14),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 100,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitSkeleton(width: 80, height: 14),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 80,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitSkeleton(width: 90, height: 14),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 72,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _CardLayoutsError extends StatelessWidget {
  const _CardLayoutsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MinglitErrorState(
        title: '카드 데이터를 불러올 수 없습니다',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: onRetry,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _CardLayoutsEmpty extends StatelessWidget {
  const _CardLayoutsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: MinglitEmptyState(
        title: '표시할 카드가 없습니다',
        subtitle: '데이터를 추가해보세요',
      ),
    );
  }
}
