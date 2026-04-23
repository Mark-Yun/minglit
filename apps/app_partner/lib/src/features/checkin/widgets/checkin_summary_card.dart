import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 체크인 현황 요약 카드.
///
/// 체크인 인원, 진행률, 마지막 업데이트 시각을 표시한다.
/// AppBar 바로 아래에 배치하며, Phase 2에서 실시간 데이터와 연동된다.
class CheckinSummaryCard extends StatelessWidget {
  const CheckinSummaryCard({
    required this.checkedIn,
    required this.total,
    this.lastUpdated,
    this.isOffline = false,
    this.isLoading = false,
    super.key,
  });

  final int checkedIn;
  final int total;
  final DateTime? lastUpdated;
  final bool isOffline;
  final bool isLoading;

  double get _ratio => total > 0 ? checkedIn / total : 0.0;

  Color _progressColor(ColorScheme scheme) {
    final ratio = _ratio;
    if (ratio >= 0.9) return scheme.error;
    if (ratio >= 0.5) return MinglitColors.warning;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton(context);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = _ratio;
    final percent = (ratio * 100).round();
    final remaining = total - checkedIn;

    return Semantics(
      label: '전체 체크인 $checkedIn명 중 $total명, $percent%',
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.screenEdge,
          vertical: MinglitSpacing.sm,
        ),
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: isOffline
              // ignore: deprecated_member_use
              ? MinglitColors.warning.withOpacity(0.08)
              : scheme.surface,
          border: Border.all(
            color: isOffline ? MinglitColors.warning : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                _CountDisplay(
                  checkedIn: checkedIn,
                  total: total,
                  textTheme: theme.textTheme,
                  scheme: scheme,
                ),
                const Spacer(),
                if (isOffline)
                  _OfflineBadge(theme: theme)
                else
                  AnimatedSwitcher(
                    duration: MinglitAnimation.medium,
                    child: Text(
                      '$percent%',
                      key: ValueKey(percent),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ratio >= 0.9 ? scheme.error : scheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: MinglitAnimation.medium,
              curve: Curves.easeOut,
              builder: (_, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: scheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation(_progressColor(scheme)),
                ),
              ),
            ),
            const SizedBox(height: MinglitSpacing.sm),
            Row(
              children: [
                _LiveDot(isOffline: isOffline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    total == 0
                        ? '아직 발급된 티켓이 없습니다'
                        : '남은 $remaining명 · ${_updateText()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _updateText() {
    if (isOffline) return '오프라인';
    final updated = lastUpdated;
    if (updated == null) return '업데이트 중';
    final diff = DateTime.now().difference(updated);
    if (diff.inSeconds < 60) return '방금 전 업데이트';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전 업데이트';
    return '${diff.inHours}시간 전 업데이트';
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.sm,
      ),
      child: const MinglitSkeleton(
        width: double.infinity,
        height: 96,
        borderRadius: BorderRadius.all(
          Radius.circular(MinglitRadius.card),
        ),
      ),
    );
  }
}

class _CountDisplay extends StatelessWidget {
  const _CountDisplay({
    required this.checkedIn,
    required this.total,
    required this.textTheme,
    required this.scheme,
  });

  final int checkedIn;
  final int total;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        AnimatedSwitcher(
          duration: MinglitAnimation.medium,
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Text(
            '$checkedIn',
            key: ValueKey(checkedIn),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        Text(
          '/$total',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: MinglitColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      child: Text(
        '캐시됨',
        style: theme.textTheme.labelSmall?.copyWith(
          color: MinglitColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.isOffline});
  final bool isOffline;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOffline
        ? MinglitColors.warning
        : MinglitColors.success;
    if (widget.isOffline) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
