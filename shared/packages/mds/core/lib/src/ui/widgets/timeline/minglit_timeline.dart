import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';
import 'package:mds/src/ui/widgets/timeline/minglit_timeline_step.dart';

export 'minglit_timeline_step.dart';

/// A vertical timeline widget that renders [MinglitTimelineStep]s
/// with tone-coloured dots and a connecting line.
class MinglitTimeline extends StatelessWidget {
  const MinglitTimeline({required this.children, super.key});

  final List<MinglitTimelineStep> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++)
          _TimelineStepItem(
            step: children[i],
            isLast: i == children.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStepItem extends StatefulWidget {
  const _TimelineStepItem({required this.step, required this.isLast});

  final MinglitTimelineStep step;
  final bool isLast;

  @override
  State<_TimelineStepItem> createState() => _TimelineStepItemState();
}

class _TimelineStepItemState extends State<_TimelineStepItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _opacityAnim = Tween<double>(begin: 1, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _startPulsingIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect OS reduced-motion preference.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (widget.step.pulsing && !_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void didUpdateWidget(_TimelineStepItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step.pulsing == oldWidget.step.pulsing) return;
    if (widget.step.pulsing) {
      if (!MediaQuery.of(context).disableAnimations && !_controller.isAnimating) {
        unawaited(_controller.repeat(reverse: true));
      }
    } else {
      _controller.stop();
    }
  }

  void _startPulsingIfNeeded() {
    if (widget.step.pulsing) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _dotFill(ThemeData theme, bool isDark) {
    return switch (widget.step.tone) {
      TimelineTone.success =>
        isDark ? MinglitColorsDark.success : MinglitColors.success,
      TimelineTone.progress => theme.colorScheme.primary,
      TimelineTone.error => theme.colorScheme.error,
      TimelineTone.neutral => theme.colorScheme.onSurfaceVariant,
      TimelineTone.muted => Colors.transparent,
    };
  }

  Color _dotBorder(ThemeData theme) {
    return widget.step.tone == TimelineTone.muted
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.surface;
  }

  Color _titleColor(ThemeData theme) {
    return switch (widget.step.tone) {
      TimelineTone.progress => theme.colorScheme.primary,
      TimelineTone.error => theme.colorScheme.error,
      TimelineTone.muted => theme.colorScheme.onSurfaceVariant,
      _ => theme.colorScheme.onSurface,
    };
  }

  Widget _buildDot(ThemeData theme, bool isDark) {
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _dotFill(theme, isDark),
        border: Border.all(color: _dotBorder(theme), width: 2),
      ),
    );

    if (widget.step.pulsing) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Opacity(opacity: _opacityAnim.value, child: child),
        ),
        child: dot,
      );
    }
    return dot;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark ? MinglitColorsDark.divider : MinglitColors.divider;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 3),
                _buildDot(theme, isDark),
                if (!widget.isLast)
                  Expanded(
                    child: Center(
                      child: Container(width: 2, color: dividerColor),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.isLast ? 0 : MinglitSpacing.xlarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.step.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _titleColor(theme),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.step.trailing != null) ...[
                        const SizedBox(width: MinglitSpacing.small),
                        DefaultTextStyle(
                          style: (theme.textTheme.bodySmall ?? const TextStyle())
                              .copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          child: widget.step.trailing!,
                        ),
                      ],
                    ],
                  ),
                  if (widget.step.child != null) ...[
                    const SizedBox(height: MinglitSpacing.xsmall),
                    widget.step.child!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
