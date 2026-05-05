import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mds/mds.dart';

enum MinglitConfirmationTone { success, primary, info, warning }

class MinglitConfirmationPalette {
  const MinglitConfirmationPalette({
    required this.circleBackground,
    required this.circleBorder,
    required this.iconColor,
  });

  final Color circleBackground;
  final Color circleBorder;
  final Color iconColor;
}

MinglitConfirmationPalette resolveMinglitConfirmationPalette(
  MinglitConfirmationTone tone,
  Brightness brightness,
) {
  final isDark = brightness == Brightness.dark;
  final primary = isDark ? MinglitColorsDark.primary : MinglitColors.primary;
  final info = isDark ? MinglitColorsDark.info : MinglitColors.info;
  final success = isDark ? MinglitColorsDark.success : MinglitColors.success;
  final warning = isDark ? MinglitColorsDark.warning : MinglitColors.warning;
  final surface = isDark ? MinglitColorsDark.surface : MinglitColors.surface;

  final base = switch (tone) {
    MinglitConfirmationTone.success => success,
    MinglitConfirmationTone.primary => primary,
    MinglitConfirmationTone.info => info,
    MinglitConfirmationTone.warning => warning,
  };

  return MinglitConfirmationPalette(
    circleBackground: Color.alphaBlend(base.withValues(alpha: 0.12), surface),
    circleBorder: base.withValues(alpha: 0.2),
    iconColor: base,
  );
}

class MinglitConfirmationPage extends StatefulWidget {
  const MinglitConfirmationPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
    required this.ctaLabel,
    required this.onPressed,
    this.autoDismiss,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final MinglitConfirmationTone tone;
  final String ctaLabel;
  final VoidCallback onPressed;
  final Duration? autoDismiss;

  @override
  State<MinglitConfirmationPage> createState() =>
      _MinglitConfirmationPageState();
}

class _MinglitConfirmationPageState extends State<MinglitConfirmationPage>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 1320);
  static const _circleDuration = 450 / 1320;
  static const _iconStart = 320 / 1320;
  static const _iconEnd = 840 / 1320;
  static const _titleStart = 880 / 1320;
  static const _titleEnd = 1080 / 1320;
  static const _descriptionStart = 980 / 1320;
  static const _descriptionEnd = 1180 / 1320;
  static const _ctaStart = 1120 / 1320;
  static const _ctaEnd = 1.0;

  late final AnimationController _controller;
  Timer? _autoDismissTimer;
  bool _didTriggerAction = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ??
        false;
    if (disableAnimations) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }

    if (_autoDismissTimer == null && widget.autoDismiss != null) {
      _autoDismissTimer = Timer(widget.autoDismiss!, _handleAction);
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleAction() {
    if (_didTriggerAction) return;
    _didTriggerAction = true;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = resolveMinglitConfirmationPalette(
      widget.tone,
      theme.brightness,
    );
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final descriptionStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final titleVisibility = _stagedVisibility(
              _titleStart,
              _titleEnd,
              offset: MinglitSpacing.small,
            );
            final descriptionVisibility = _stagedVisibility(
              _descriptionStart,
              _descriptionEnd,
              offset: MinglitSpacing.small,
            );
            final ctaVisibility = _stagedVisibility(
              _ctaStart,
              _ctaEnd,
              offset: MinglitSpacing.small,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.screenEdge,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Transform.scale(
                    scale: Curves.elasticOut.transform(
                      _interval(0, _circleDuration),
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.circleBackground,
                        border: Border.all(color: palette.circleBorder),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: CustomPaint(
                            painter: _ConfirmationIconPainter(
                              icon: widget.icon,
                              tone: widget.tone,
                              color: palette.iconColor,
                              progress: Curves.easeInOutQuart.transform(
                                _interval(_iconStart, _iconEnd),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                  Opacity(
                    opacity: titleVisibility.opacity,
                    child: Transform.translate(
                      offset: Offset(0, titleVisibility.dy),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: titleStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.sm),
                  Opacity(
                    opacity: descriptionVisibility.opacity,
                    child: Transform.translate(
                      offset: Offset(0, descriptionVisibility.dy),
                      child: Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: descriptionStyle,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Opacity(
                    opacity: ctaVisibility.opacity,
                    child: Transform.translate(
                      offset: Offset(0, ctaVisibility.dy),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: MinglitSpacing.large,
                        ),
                        child: MinglitButton(
                          label: widget.ctaLabel,
                          onPressed: _handleAction,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _VisibilityState _stagedVisibility(
    double begin,
    double end, {
    required double offset,
  }) {
    final progress = Curves.easeOut.transform(_interval(begin, end));
    return _VisibilityState(
      opacity: progress,
      dy: (1 - progress) * offset,
    );
  }

  double _interval(double begin, double end) {
    return Interval(begin, end).transform(_controller.value);
  }
}

class _VisibilityState {
  const _VisibilityState({required this.opacity, required this.dy});

  final double opacity;
  final double dy;
}

class _ConfirmationIconPainter extends CustomPainter {
  const _ConfirmationIconPainter({
    required this.icon,
    required this.tone,
    required this.color,
    required this.progress,
  });

  final IconData icon;
  final MinglitConfirmationTone tone;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.length,
    );
    var remaining = totalLength * progress.clamp(0, 1);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in metrics) {
      if (remaining <= 0) break;
      final drawLength = math.min(metric.length, remaining);
      canvas.drawPath(metric.extractPath(0, drawLength), paint);
      remaining -= drawLength;
    }
  }

  Path _buildPath(Size size) {
    if (_isInfoIcon) {
      return _infoPath(size);
    }
    if (_isWarningIcon) {
      return _warningPath(size);
    }
    return _checkPath(size);
  }

  bool get _isInfoIcon =>
      tone == MinglitConfirmationTone.info ||
      icon == Icons.info_outline_rounded ||
      icon == Icons.info_rounded;

  bool get _isWarningIcon =>
      tone == MinglitConfirmationTone.warning ||
      icon == Icons.warning_amber_rounded ||
      icon == Icons.warning_rounded;

  Path _checkPath(Size size) {
    final width = size.width;
    final height = size.height;
    return Path()
      ..moveTo(width * 0.22, height * 0.55)
      ..lineTo(width * 0.44, height * 0.76)
      ..lineTo(width * 0.8, height * 0.3);
  }

  Path _infoPath(Size size) {
    final width = size.width;
    final height = size.height;
    return Path()
      ..moveTo(width * 0.5, height * 0.26)
      ..lineTo(width * 0.5, height * 0.28)
      ..moveTo(width * 0.5, height * 0.42)
      ..lineTo(width * 0.5, height * 0.76);
  }

  Path _warningPath(Size size) {
    final width = size.width;
    final height = size.height;
    return Path()
      ..moveTo(width * 0.5, height * 0.18)
      ..lineTo(width * 0.82, height * 0.78)
      ..lineTo(width * 0.18, height * 0.78)
      ..close()
      ..moveTo(width * 0.5, height * 0.38)
      ..lineTo(width * 0.5, height * 0.58)
      ..moveTo(width * 0.5, height * 0.68)
      ..lineTo(width * 0.5, height * 0.7);
  }

  @override
  bool shouldRepaint(covariant _ConfirmationIconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.icon != icon ||
        oldDelegate.tone != tone;
  }
}
