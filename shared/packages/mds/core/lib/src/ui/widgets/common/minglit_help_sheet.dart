import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';

/// A section entry displayed inside [MinglitHelpSheet].
class HelpSection {
  const HelpSection({
    required this.title,
    required this.body,
    this.leading,
  });

  /// Optional icon or chip widget shown before [title] (18×18 partner-primary).
  final Widget? leading;

  /// Section question text (e.g. "파티가 뭔가요?").
  final String title;

  /// Answer/explanation text.
  final String body;
}

/// Shows a Minglit-styled help bottom sheet.
///
/// Displays a scrollable Q&A sheet with a sticky confirm CTA.
/// The sheet is dismiss-able via handle drag-down, scrim tap, or system back.
///
/// {@tool snippet}
/// ```dart
/// showMinglitHelpSheet(
///   context: context,
///   title: '파티 관리 가이드',
///   sections: [
///     HelpSection(title: '파티가 뭔가요?', body: '...'),
///     HelpSection(leading: Icon(Icons.info), title: '파티와 파티장의 차이?', body: '...'),
///   ],
/// );
/// ```
/// {@end-tool}
Future<void> showMinglitHelpSheet({
  required BuildContext context,
  required String title,
  required List<HelpSection> sections,
  String confirmLabel = '확인',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: MinglitOpacity.gradient),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MinglitRadius.card),
      ),
    ),
    builder: (ctx) => _MinglitHelpSheetContent(
      title: title,
      sections: sections,
      confirmLabel: confirmLabel,
    ),
  );
}

class _MinglitHelpSheetContent extends StatelessWidget {
  const _MinglitHelpSheetContent({
    required this.title,
    required this.sections,
    required this.confirmLabel,
  });

  final String title;
  final List<HelpSection> sections;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    final partnerPrimary =
        isDark ? MinglitPartnerColorsDark.primary : MinglitPartnerColors.primary;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ③ Handle bar
            const SizedBox(height: MinglitSpacing.small),
            _HelpHandle(color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: MinglitSpacing.xsmall),
            // ④ Header
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.small,
                horizontal: MinglitSpacing.medium,
              ),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  // ignore: minglit_no_hardcoded_text_style -- local override for 16/700
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            // ⑤ Scrollable body
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                itemCount: sections.length,
                itemBuilder: (_, index) => _HelpSectionItem(
                  section: sections[index],
                  showTopDivider: index > 0,
                  theme: theme,
                  partnerPrimary: partnerPrimary,
                ),
              ),
            ),
            // ⑧ Sticky CTA
            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: partnerPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MinglitRadius.button),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      // ignore: minglit_no_hardcoded_text_style -- spec: 15/700 white
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHandle extends StatelessWidget {
  const _HelpHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: MinglitOpacity.muted),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const SizedBox(width: 36, height: 4),
      ),
    );
  }
}

class _HelpSectionItem extends StatelessWidget {
  const _HelpSectionItem({
    required this.section,
    required this.showTopDivider,
    required this.theme,
    required this.partnerPrimary,
  });

  final HelpSection section;
  final bool showTopDivider;
  final ThemeData theme;
  final Color partnerPrimary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: showTopDivider
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
            )
          : const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⑥ Section title row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (section.leading != null) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: IconTheme(
                      data: IconThemeData(
                        size: 18,
                        color: partnerPrimary,
                      ),
                      child: section.leading!,
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.xsmall),
                ],
                Expanded(
                  child: Text(
                    section.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      // ignore: minglit_no_hardcoded_text_style -- spec: 14/700 primary
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            // ⑦ Section body
            const SizedBox(height: MinglitSpacing.xxsmall),
            Text(
              section.body,
              style: theme.textTheme.bodySmall?.copyWith(
                // ignore: minglit_no_hardcoded_text_style -- spec: 13/regular secondary, height 1.55
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
