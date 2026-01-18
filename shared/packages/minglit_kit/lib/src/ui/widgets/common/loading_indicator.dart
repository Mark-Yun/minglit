import 'package:flutter/material.dart';

class MinglitCircularProgressIndicator extends StatelessWidget {
  const MinglitCircularProgressIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          // ignore: use_minglit_progress_indicator
          strokeWidth: strokeWidth,
          valueColor: color != null
              ? AlwaysStoppedAnimation<Color>(color!)
              : null,
        ),
      ),
    );
  }
}

class MinglitLinearProgressIndicator extends StatelessWidget {
  const MinglitLinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
  });

  final double? value;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      // ignore: use_minglit_progress_indicator
      value: value,
      color: color,
      backgroundColor: backgroundColor,
    );
  }
}
