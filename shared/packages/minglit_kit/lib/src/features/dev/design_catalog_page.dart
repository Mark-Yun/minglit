import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_alert.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_badge.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_dialog.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_empty_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_error_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_filter_chip.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_key_value_row.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_list_tile.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_participant_gauge.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section_divider.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_tag.dart';

/// Dev-only design catalog page displaying all design tokens and components.
///
/// Organized into two sections:
/// - **Tokens** (6 tabs): design foundation values
/// - **Widgets** (8 tabs): reusable Minglit components
///
/// Shared between user and partner apps. Only accessible when
/// `ENVIRONMENT` is `development` or `local`.
class DesignCatalogPage extends StatelessWidget {
  /// Creates a [DesignCatalogPage].
  const DesignCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // Fix #621: 16탭 → 14탭 (토큰 6 + 위젯 8) 재구성
      length: 14,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Design Catalog'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              // Tokens (6)
              Tab(text: 'Colors'),
              Tab(text: 'Typography'),
              Tab(text: 'Spacing'),
              Tab(text: 'Radius'),
              Tab(text: 'IconSize'),
              Tab(text: 'Animation'),
              // Widgets (8)
              Tab(text: 'Layout'),
              Tab(text: 'Buttons'),
              Tab(text: 'Inputs'),
              Tab(text: 'Cards'),
              Tab(text: 'Feedback'),
              Tab(text: 'Overlay'),
              Tab(text: 'Data'),
              Tab(text: 'Loading'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Tokens (6)
            _ColorsSection(),
            _TypographySection(),
            _SpacingSection(),
            _RadiusSection(),
            _IconSizeSection(),
            _AnimationSection(),
            // Widgets (8)
            _LayoutSection(),
            _ButtonsSection(),
            _InputsSection(),
            _CardsSection(),
            _FeedbackSection(),
            _OverlaySection(),
            _DataSection(),
            _LoadingSection(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// TOKEN SECTIONS (6)
// ===========================================================================

// ---------------------------------------------------------------------------
// Colors Section
// ---------------------------------------------------------------------------

class _ColorsSection extends StatelessWidget {
  const _ColorsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Light Colors', style: theme.textTheme.titleLarge),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            _ColorChip('background', MinglitColors.background),
            _ColorChip('primary', MinglitColors.primary),
            _ColorChip('secondary', MinglitColors.secondary),
            _ColorChip('tertiary', MinglitColors.tertiary),
            _ColorChip('surface', MinglitColors.surface),
            _ColorChip('error', MinglitColors.error),
            _ColorChip('textPrimary', MinglitColors.textPrimary),
            _ColorChip('textSecondary', MinglitColors.textSecondary),
            _ColorChip('success', MinglitColors.success),
            _ColorChip('warning', MinglitColors.warning),
            _ColorChip('transparent', MinglitColors.transparent),
            _ColorChip('scrim', MinglitColors.scrim),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Dark Colors', style: theme.textTheme.titleLarge),
        const SizedBox(height: MinglitSpacing.small),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          decoration: BoxDecoration(
            color: MinglitColorsDark.background,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: const Wrap(
            spacing: MinglitSpacing.small,
            runSpacing: MinglitSpacing.small,
            children: [
              _ColorChip(
                'background',
                MinglitColorsDark.background,
                darkBg: true,
              ),
              _ColorChip('surface', MinglitColorsDark.surface, darkBg: true),
              _ColorChip(
                'textPrimary',
                MinglitColorsDark.textPrimary,
                darkBg: true,
              ),
              _ColorChip(
                'textSecondary',
                MinglitColorsDark.textSecondary,
                darkBg: true,
              ),
              _ColorChip('primary', MinglitColorsDark.primary, darkBg: true),
              _ColorChip(
                'secondary',
                MinglitColorsDark.secondary,
                darkBg: true,
              ),
              _ColorChip('tertiary', MinglitColorsDark.tertiary, darkBg: true),
              _ColorChip('error', MinglitColorsDark.error, darkBg: true),
              _ColorChip('divider', MinglitColorsDark.divider, darkBg: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip(this.name, this.color, {this.darkBg = false});

  final String name;
  final Color color;
  final bool darkBg;

  @override
  Widget build(BuildContext context) {
    final hex =
        // ignore: deprecated_member_use
        '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final labelColor = darkBg ? MinglitColorsDark.textPrimary : null;
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
              border: Border.all(
                color: darkBg
                    ? MinglitColorsDark.divider
                    : MinglitColors.textSecondary.withAlpha(50),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            hex,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: labelColor ?? MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Typography Section
// ---------------------------------------------------------------------------

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final styles = <String, TextStyle?>{
      'displayLarge': textTheme.displayLarge,
      'displayMedium': textTheme.displayMedium,
      'displaySmall': textTheme.displaySmall,
      'headlineLarge': textTheme.headlineLarge,
      'headlineMedium': textTheme.headlineMedium,
      'headlineSmall': textTheme.headlineSmall,
      'titleLarge': textTheme.titleLarge,
      'titleMedium': textTheme.titleMedium,
      'titleSmall': textTheme.titleSmall,
      'bodyLarge': textTheme.bodyLarge,
      'bodyMedium': textTheme.bodyMedium,
      'bodySmall': textTheme.bodySmall,
      'labelLarge': textTheme.labelLarge,
      'labelMedium': textTheme.labelMedium,
      'labelSmall': textTheme.labelSmall,
    };

    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: styles.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final entry = styles.entries.elementAt(index);
        final style = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: style ?? const TextStyle()),
              const SizedBox(height: MinglitSpacing.xsmall),
              Text(
                'size: ${style?.fontSize ?? "inherit"} '
                '/ weight: ${style?.fontWeight ?? "inherit"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: MinglitColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Spacing Section
// ---------------------------------------------------------------------------

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const spacings = <String, double>{
      'zero': MinglitSpacing.zero,
      'xxsmall (2)': MinglitSpacing.xxsmall,
      'xsmall (4)': MinglitSpacing.xsmall,
      'xsmall2 (6)': MinglitSpacing.xsmall2,
      'small (8)': MinglitSpacing.small,
      'sm (12)': MinglitSpacing.sm,
      'medium (16)': MinglitSpacing.medium,
      'large (24)': MinglitSpacing.large,
      'xlarge (32)': MinglitSpacing.xlarge,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: spacings.length,
      itemBuilder: (context, index) {
        final entry = spacings.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.key, style: theme.textTheme.bodyMedium),
              ),
              Container(
                width: entry.value,
                height: 24,
                decoration: BoxDecoration(
                  color: MinglitColors.primary.withAlpha(180),
                  borderRadius: BorderRadius.circular(MinglitRadius.small),
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Text(
                '${entry.value.toInt()}px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MinglitColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Radius Section
// ---------------------------------------------------------------------------

class _RadiusSection extends StatelessWidget {
  const _RadiusSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radii = <String, double>{
      'small (8)': MinglitRadius.small,
      'input (12)': MinglitRadius.input,
      'button (16)': MinglitRadius.button,
      'card (24)': MinglitRadius.card,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: radii.length,
      itemBuilder: (context, index) {
        final entry = radii.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.key, style: theme.textTheme.bodyMedium),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MinglitColors.primary.withAlpha(30),
                  border: Border.all(color: MinglitColors.primary),
                  borderRadius: BorderRadius.circular(entry.value),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${entry.value.toInt()}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// IconSize Section
// ---------------------------------------------------------------------------

class _IconSizeSection extends StatelessWidget {
  const _IconSizeSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const sizes = <String, double>{
      'xsmall (16)': MinglitIconSize.xsmall,
      'small (20)': MinglitIconSize.small,
      'medium (24)': MinglitIconSize.medium,
      'large (28)': MinglitIconSize.large,
      'xlarge (32)': MinglitIconSize.xlarge,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: sizes.length,
      itemBuilder: (context, index) {
        final entry = sizes.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.key, style: theme.textTheme.bodyMedium),
              ),
              Icon(Icons.star, size: entry.value),
              const SizedBox(width: MinglitSpacing.small),
              Icon(Icons.favorite, size: entry.value),
              const SizedBox(width: MinglitSpacing.small),
              Icon(Icons.notifications, size: entry.value),
              const SizedBox(width: MinglitSpacing.medium),
              Text(
                '${entry.value.toInt()}px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MinglitColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Animation Section
// ---------------------------------------------------------------------------

class _AnimationSection extends StatefulWidget {
  const _AnimationSection();

  @override
  State<_AnimationSection> createState() => _AnimationSectionState();
}

class _AnimationSectionState extends State<_AnimationSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetWidth = _expanded ? 200.0 : 80.0;

    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Animation Durations', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Tap the button to toggle animated containers.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        ElevatedButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Collapse' : 'Expand'),
        ),
        const SizedBox(height: MinglitSpacing.large),
        _AnimationRow(
          label: 'fast (200ms)',
          duration: MinglitAnimation.fast,
          targetWidth: targetWidth,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        _AnimationRow(
          label: 'medium (350ms)',
          duration: MinglitAnimation.medium,
          targetWidth: targetWidth,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        _AnimationRow(
          label: 'slow (500ms)',
          duration: MinglitAnimation.slow,
          targetWidth: targetWidth,
        ),
      ],
    );
  }
}

class _AnimationRow extends StatelessWidget {
  const _AnimationRow({
    required this.label,
    required this.duration,
    required this.targetWidth,
  });

  final String label;
  final Duration duration;
  final double targetWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          width: targetWidth,
          height: 40,
          decoration: BoxDecoration(
            color: MinglitColors.primary.withAlpha(180),
            borderRadius: BorderRadius.circular(MinglitRadius.small),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// WIDGET SECTIONS (8)
// ===========================================================================

// ---------------------------------------------------------------------------
// Layout: MinglitSection, MinglitContentCard, MinglitKeyValueRow,
//         MinglitSectionDivider
// ---------------------------------------------------------------------------

class _LayoutSection extends StatelessWidget {
  const _LayoutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleLarge = theme.textTheme.titleLarge;

    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // 1. MinglitSection
        Text('MinglitSection', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitSection(
          title: '참여 현황',
          child: Text('섹션 콘텐츠가 여기에'),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitSection(
          title: '이번 주 성과',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('더보기'),
          ),
          child: const Text('trailing 액션 포함'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 2. MinglitContentCard
        Text('MinglitContentCard', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitContentCard(
          child: Column(
            children: [
              Text('기본 카드'),
              Text('내부 패딩과 radius가 통일됩니다'),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.sm),
        const MinglitContentCard(
          highlighted: true,
          child: Text('highlighted 카드 (primary 보더)'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 3. MinglitKeyValueRow
        Text('MinglitKeyValueRow', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitContentCard(
          child: Column(
            children: [
              MinglitKeyValueRow(label: '총 매출', value: '₩420,000'),
              MinglitKeyValueRow(label: '수수료', value: '-₩42,000'),
              Divider(),
              MinglitKeyValueRow(
                label: '정산금',
                value: '₩378,000',
                bold: true,
              ),
            ],
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 4. MinglitSectionDivider
        Text('MinglitSectionDivider', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        Text('thick (8px)', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const Text('Content above'),
        const MinglitSectionDivider.thick(),
        const Text('Content below'),
        const SizedBox(height: MinglitSpacing.large),
        Text('thin (1px)', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const Text('Content above'),
        const MinglitSectionDivider.thin(),
        const Text('Content below'),

        const Divider(height: MinglitSpacing.xxlarge),

        // 5. 조합 예시
        Text('조합 예시', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitSection(
          title: '정산 요약',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('상세 ›'),
          ),
          child: const MinglitContentCard(
            child: Column(
              children: [
                MinglitKeyValueRow(
                  label: '이번 달',
                  value: '₩1,280,000',
                  bold: true,
                ),
                MinglitKeyValueRow(
                  label: '정산 완료',
                  value: '₩850,000',
                ),
                MinglitKeyValueRow(
                  label: '정산 대기',
                  value: '₩430,000',
                ),
              ],
            ),
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 5. MinglitListTile
        Text('MinglitListTile', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitListTile(title: '기본 타일 (title only)'),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitListTile(
          title: '홍길동',
          subtitle: '파트너 매니저',
        ),
        const SizedBox(height: MinglitSpacing.small),
        MinglitListTile(
          title: '아바타 + trailing',
          subtitle: '네트워크 이미지 예시',
          avatar: const AssetImage(
            'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitListTile(
          title: '비활성 타일',
          subtitle: 'enabled: false',
          leading: Icon(Icons.block),
          enabled: false,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons: ElevatedButton, OutlinedButton, TextButton, MinglitChip,
//          MinglitFilterChip
// ---------------------------------------------------------------------------

class _ButtonsSection extends StatefulWidget {
  const _ButtonsSection();

  @override
  State<_ButtonsSection> createState() => _ButtonsSectionState();
}

class _ButtonsSectionState extends State<_ButtonsSection> {
  bool _filterSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('ElevatedButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              const Text('Loading...'),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('OutlinedButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        OutlinedButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const OutlinedButton(onPressed: null, child: Text('Disabled')),
        const SizedBox(height: MinglitSpacing.large),
        Text('TextButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        TextButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const TextButton(onPressed: null, child: Text('Disabled')),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitChip
        Text('MinglitChip', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitChip(label: 'Default'),
            MinglitChip(label: 'With Icon', icon: Icons.flutter_dash),
            MinglitChip(
              label: 'Small',
              size: MinglitChipSize.small,
              icon: Icons.star,
            ),
            MinglitChip(
              label: 'Large',
              size: MinglitChipSize.large,
            ),
            MinglitChip(
              label: 'Colored',
              color: MinglitColors.primary,
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitFilterChip
        Text('MinglitFilterChip', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitFilterChip(
              label: '최신순',
              isSelected: _filterSelected,
              icon: Icons.sort,
              onTap: () => setState(() => _filterSelected = !_filterSelected),
            ),
            MinglitFilterChip(
              label: '인기순',
              isSelected: !_filterSelected,
              onTap: () => setState(() => _filterSelected = !_filterSelected),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inputs: TextField, Checkbox
// ---------------------------------------------------------------------------

class _InputsSection extends StatefulWidget {
  const _InputsSection();

  @override
  State<_InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<_InputsSection> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // TextField demos
        Text('TextField', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Normal input field',
            labelText: 'Label',
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('With Value', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        TextFormField(
          initialValue: 'Minglit',
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Error State', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Error input',
            labelText: 'Email',
            errorText: 'Invalid email format',
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Disabled', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Disabled input field',
            labelText: 'Disabled',
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('With Prefix & Suffix', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.clear),
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // Checkbox demos
        Text('Checkbox', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        CheckboxListTile(
          title: const Text('Selected'),
          value: _checked,
          onChanged: (v) => setState(() => _checked = v ?? false),
        ),
        CheckboxListTile(
          title: const Text('Unselected'),
          value: false,
          onChanged: (v) {},
        ),
        const CheckboxListTile(
          title: Text('Disabled (selected)'),
          value: true,
          onChanged: null,
        ),
        const CheckboxListTile(
          title: Text('Disabled (unselected)'),
          value: false,
          onChanged: null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cards: Material Card, MinglitContentCard, MinglitTag, MinglitBadge
// ---------------------------------------------------------------------------

class _CardsSection extends StatelessWidget {
  const _CardsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // Material Card elevations
        Text('Card Elevations', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        for (final elevation in [0.0, 1.0, 2.0, 4.0]) ...[
          Card(
            elevation: elevation,
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Text('Card elevation ${elevation.toInt()}'),
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
        ],

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitContentCard
        Text('MinglitContentCard', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(child: Text('기본 카드')),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          highlighted: true,
          child: Text('highlighted 카드 (primary 보더)'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitTag
        Text('MinglitTag', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitTag(label: '음악', color: MinglitColors.primary),
            MinglitTag(label: '승인', color: MinglitColors.success),
            MinglitTag(label: '대기', color: MinglitColors.warning),
            MinglitTag(label: '취소', color: MinglitColors.error),
            MinglitTag(
              label: '카테고리',
              color: MinglitColors.primary,
              icon: Icons.category,
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Small', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitTag(
              label: '음악',
              color: MinglitColors.primary,
              size: MinglitTagSize.small,
            ),
            MinglitTag(
              label: '승인',
              color: MinglitColors.success,
              size: MinglitTagSize.small,
            ),
            MinglitTag(
              label: '아이콘',
              color: MinglitColors.warning,
              size: MinglitTagSize.small,
              icon: Icons.star,
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitBadge
        Text('MinglitBadge', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitBadge(label: '승인됨', color: MinglitColors.success),
            MinglitBadge(label: '대기', color: MinglitColors.warning),
            MinglitBadge(label: '거절', color: MinglitColors.error),
            MinglitBadge(label: '정산', color: MinglitColors.primary),
            MinglitBadge(
              label: 'compact',
              color: MinglitColors.primary,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Feedback: MinglitEmptyState, MinglitErrorState, MinglitAlert, MinglitDialog
// ---------------------------------------------------------------------------

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // MinglitEmptyState
        Text('MinglitEmptyState', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: MinglitEmptyState(
            title: '저장된 항목이 없습니다',
            subtitle: '새로운 항목을 추가해보세요',
            actionLabel: '새로 만들기',
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitErrorState
        Text('MinglitErrorState', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: MinglitErrorState(
            title: '데이터를 불러올 수 없습니다',
            subtitle: '네트워크 연결을 확인해주세요',
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitAlert
        Text('MinglitAlert', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Tap buttons to preview alerts.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        ElevatedButton(
          onPressed: () {
            unawaited(
              MinglitAlert.show(
                context: context,
                title: '알림',
                content: '작업이 완료되었습니다.',
              ),
            );
          },
          child: const Text('Show Info Alert'),
        ),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              MinglitAlert.showConfirm(
                context: context,
                title: '삭제하시겠습니까?',
                content: '이 작업은 되돌릴 수 없습니다.',
                isDestructive: true,
              ),
            );
          },
          child: const Text('Show Destructive Confirm'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitDialog
        Text('MinglitDialog', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              MinglitDialog.show(
                context: context,
                title: '커스텀 다이얼로그',
                content: const Text('MinglitDialog는 제목 + 콘텐츠 + 액션을 조합합니다.'),
              ),
            );
          },
          child: const Text('Show MinglitDialog'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay: AlertDialog, BottomSheet
// ---------------------------------------------------------------------------

class _OverlaySection extends StatelessWidget {
  const _OverlaySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // AlertDialog
        Text('AlertDialog', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Action'),
                  content: const Text('Are you sure you want to proceed?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show AlertDialog'),
        ),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Item'),
                  content: const Text(
                    'This action cannot be undone. '
                    'Are you sure you want to delete?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // ignore: minglit_no_hardcoded_colors -- catalog demo
                        backgroundColor: MinglitColors.error,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show Destructive Dialog'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // BottomSheet
        Text('BottomSheet', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.large),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example BottomSheet',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: MinglitSpacing.medium),
                      Text(
                        'This is an example modal bottom sheet '
                        'using the current theme.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: MinglitSpacing.large),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(height: MinglitSpacing.medium),
                    ],
                  ),
                ),
              ),
            );
          },
          child: const Text('Show BottomSheet'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data: MinglitParticipantGauge, MinglitKeyValueRow, MinglitImage,
//       MinglitImageCarousel
// ---------------------------------------------------------------------------

class _DataSection extends StatelessWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // MinglitParticipantGauge
        Text('MinglitParticipantGauge', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Row(
          children: [
            Expanded(
              child: MinglitContentCard(
                child: Column(
                  children: [
                    Text('25%'),
                    SizedBox(height: MinglitSpacing.small),
                    MinglitParticipantGauge(current: 5, max: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: MinglitSpacing.small),
            Expanded(
              child: MinglitContentCard(
                child: Column(
                  children: [
                    Text('50%'),
                    SizedBox(height: MinglitSpacing.small),
                    MinglitParticipantGauge(current: 10, max: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: MinglitSpacing.small),
            Expanded(
              child: MinglitContentCard(
                child: Column(
                  children: [
                    Text('90%'),
                    SizedBox(height: MinglitSpacing.small),
                    MinglitParticipantGauge(current: 18, max: 20),
                  ],
                ),
              ),
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitKeyValueRow (cross-ref from Layout)
        Text('MinglitKeyValueRow', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: Column(
            children: [
              MinglitKeyValueRow(label: '주최', value: '밍글릿'),
              MinglitKeyValueRow(label: '장소', value: '강남 스퀘어'),
              MinglitKeyValueRow(label: '참가비', value: '₩15,000'),
            ],
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitImage
        Text('MinglitImage', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Network image with automatic placeholder/error handling.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: MinglitImage(
            path: 'https://picsum.photos/400/200',
            height: 150,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading: MinglitSkeleton, MinglitCircularProgressIndicator,
//          MinglitLinearProgressIndicator
// ---------------------------------------------------------------------------

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // MinglitSkeleton
        Text('MinglitSkeleton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitSkeleton(width: 200, height: 20),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitSkeleton(width: 150, height: 20),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Card skeleton',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitCircularProgressIndicator
        Text(
          'MinglitCircularProgressIndicator',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        const Row(
          children: [
            MinglitCircularProgressIndicator(),
            SizedBox(width: MinglitSpacing.large),
            MinglitCircularProgressIndicator(
              size: 32,
              strokeWidth: 3,
            ),
            SizedBox(width: MinglitSpacing.large),
            MinglitCircularProgressIndicator(
              size: 48,
              strokeWidth: 4,
              color: MinglitColors.success,
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitLinearProgressIndicator
        Text(
          'MinglitLinearProgressIndicator',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text('Indeterminate', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(),
        const SizedBox(height: MinglitSpacing.medium),
        Text('30%', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(value: 0.3),
        const SizedBox(height: MinglitSpacing.medium),
        Text('70%', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(value: 0.7),
        const SizedBox(height: MinglitSpacing.medium),
        Text('100%', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(
          value: 1,
          color: MinglitColors.success,
        ),
      ],
    );
  }
}
