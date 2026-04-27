import 'package:flutter/material.dart';

/// A centered circular progress indicator with configurable size.
class MinglitCircularProgressIndicator extends StatelessWidget {
  /// Creates a circular progress indicator.
  const MinglitCircularProgressIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2,
    this.color,
  });

  /// The width and height of the indicator.
  final double size;

  /// The stroke width of the progress ring.
  final double strokeWidth;

  /// Optional color override for the indicator.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        // ignore: use_minglit_progress_indicator, this IS the MinglitCircularProgressIndicator implementation
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: color != null
              ? AlwaysStoppedAnimation<Color>(color!)
              : null,
        ),
      ),
    );
  }
}

/// A linear progress indicator with optional value and colors.
class MinglitLinearProgressIndicator extends StatelessWidget {
  /// Creates a linear progress indicator.
  const MinglitLinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
  });

  /// Current progress value from 0.0 to 1.0.
  final double? value;

  /// The indicator color.
  final Color? color;

  /// The background track color.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    // ignore: use_minglit_progress_indicator, this IS the MinglitLinearProgressIndicator implementation
    return LinearProgressIndicator(
      value: value,
      color: color,
      backgroundColor: backgroundColor,
    );
  }
}
