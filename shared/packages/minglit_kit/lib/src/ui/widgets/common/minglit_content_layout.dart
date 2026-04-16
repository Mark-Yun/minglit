import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section_divider.dart';

/// 상세 페이지의 섹션들을 통일된 간격으로 나열하는 콘텐츠 레이아웃.
/// 모든 상세 페이지(이벤트, 파트너, 정산 등)에서 재사용.
///
/// 스크롤은 부모 위젯이 관리합니다. 이 위젯은 Column 기반으로
/// CustomScrollView(SliverToBoxAdapter), SingleChildScrollView 등
/// 어떤 스크롤 컨텍스트에서도 안전하게 사용할 수 있습니다.
class MinglitContentLayout extends StatelessWidget {
  const MinglitContentLayout({
    required this.sections,
    this.sectionGap,
    this.topPadding,
    this.bottomPadding,
    this.showDividers = false,
    super.key,
  });

  /// 표시할 섹션 위젯 목록 (MinglitSection 권장)
  final List<Widget> sections;

  /// 섹션 간 간격. 기본값: MinglitSpacing.sectionGap (40px)
  final double? sectionGap;

  /// 첫 섹션 위 여백. 기본값: MinglitSpacing.large (24px)
  final double? topPadding;

  /// 마지막 섹션 아래 여백. 기본값: MinglitSpacing.xlarge (32px)
  final double? bottomPadding;

  /// 섹션 간 시각적 구분선 표시 여부. 기본값: false
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveSectionGap = sectionGap ?? MinglitSpacing.sectionGap;
    final effectiveTopPadding = topPadding ?? MinglitSpacing.large;
    final effectiveBottomPadding = bottomPadding ?? MinglitSpacing.xlarge;
    final halfGap = effectiveSectionGap / 2;

    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      children.add(sections[i]);

      if (i < sections.length - 1) {
        if (showDividers) {
          children.add(SizedBox(height: halfGap));
          children.add(const MinglitSectionDivider.thin());
          children.add(SizedBox(height: halfGap));
        } else {
          children.add(SizedBox(height: effectiveSectionGap));
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        top: effectiveTopPadding,
        bottom: effectiveBottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
