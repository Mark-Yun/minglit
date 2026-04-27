import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';

/// 가로 스크롤 affordance 래퍼 위젯.
///
/// 내부 스크롤 위치에 따라 양방향 엣지 페이드와 오른쪽 Chevron 인디케이터를 표시한다.
/// - 왼쪽 페이드: `extentBefore > 0` (우측으로 스크롤된 상태)
/// - 오른쪽 페이드 + Chevron: `extentAfter > 0` (오른쪽에 숨겨진 콘텐츠 존재)
class MinglitHorizontalScrollGroup extends StatefulWidget {
  const MinglitHorizontalScrollGroup({required this.child, super.key});

  /// 가로 스크롤 가능한 위젯 (예: ListView, SingleChildScrollView).
  final Widget child;

  @override
  State<MinglitHorizontalScrollGroup> createState() =>
      _MinglitHorizontalScrollGroupState();
}

class _MinglitHorizontalScrollGroupState
    extends State<MinglitHorizontalScrollGroup> {
  bool _showLeftFade = false;
  bool _showRightFade = false;

  static const double _fadeWidth = MinglitSpacing.medium;
  static const double _chevronSize = 16;

  void _handleMetrics(ScrollMetrics metrics) {
    if (!mounted) return;
    final showLeft = metrics.extentBefore > 0;
    final showRight = metrics.extentAfter > 0;
    if (showLeft != _showLeftFade || showRight != _showRightFade) {
      setState(() {
        _showLeftFade = showLeft;
        _showRightFade = showRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final chevronColor = Theme.of(context).colorScheme.onSurfaceVariant
        // ignore: deprecated_member_use
        .withOpacity(0.4);

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _handleMetrics(n.metrics);
        return false;
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) {
          _handleMetrics(n.metrics);
          return false;
        },
        child: Stack(
          children: [
            widget.child,
            if (_showLeftFade)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: _fadeWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          surfaceColor,
                          // ignore: deprecated_member_use
                          surfaceColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_showRightFade)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _fadeWidth,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              surfaceColor,
                              // ignore: deprecated_member_use
                              surfaceColor.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                      ColoredBox(
                        color: surfaceColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.chevron_right,
                            size: _chevronSize,
                            color: chevronColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
