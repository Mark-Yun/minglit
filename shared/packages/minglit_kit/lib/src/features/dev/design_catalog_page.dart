import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_key_value_row.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_tag.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_text_field.dart';

/// Dev-only design catalog page displaying all design tokens and components.
///
/// Shared between user and partner apps. Only accessible when
/// `ENVIRONMENT` is `development` or `local`.
class DesignCatalogPage extends StatelessWidget {
  /// Creates a [DesignCatalogPage].
  const DesignCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 16,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Design Catalog'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Colors'),
              Tab(text: 'Typography'),
              Tab(text: 'Spacing'),
              Tab(text: 'Radius'),
              Tab(text: 'Buttons'),
              Tab(text: 'Cards'),
              Tab(text: 'Inputs'),
              Tab(text: 'Dialogs'),
              Tab(text: 'BottomSheet'),
              Tab(text: 'Badge/Tag'),
              Tab(text: 'Checkbox'),
              Tab(text: 'TabBar'),
              Tab(text: 'Divider'),
              Tab(text: 'IconSize'),
              Tab(text: 'Animation'),
              Tab(text: 'Layout'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ColorsSection(),
            _TypographySection(),
            _SpacingSection(),
            _RadiusSection(),
            _ButtonsSection(),
            _CardsSection(),
            _InputsSection(),
            _DialogsSection(),
            _BottomSheetSection(),
            _BadgeTagSection(),
            _CheckboxSection(),
            _TabBarSection(),
            _DividerSection(),
            _IconSizeSection(),
            _AnimationSection(),
            _LayoutSection(),
          ],
        ),
      ),
    );
  }
}

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
// Buttons Section
// ---------------------------------------------------------------------------

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection();

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
        const SizedBox(height: MinglitSpacing.small),
        OutlinedButton(
          onPressed: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              const Text('Loading...'),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('TextButton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        TextButton(onPressed: () {}, child: const Text('Enabled')),
        const SizedBox(height: MinglitSpacing.small),
        const TextButton(onPressed: null, child: Text('Disabled')),
        const SizedBox(height: MinglitSpacing.small),
        TextButton(
          onPressed: null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              const Text('Loading...'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cards Section
// ---------------------------------------------------------------------------

class _CardsSection extends StatelessWidget {
  const _CardsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Default Card (elevation 0)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(MinglitSpacing.medium),
            child: Text('Card with theme default (elevation 0)'),
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Elevation 1', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Card(
          elevation: 1,
          child: Padding(
            padding: EdgeInsets.all(MinglitSpacing.medium),
            child: Text('Card with elevation 1'),
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Elevation 2', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(MinglitSpacing.medium),
            child: Text('Card with elevation 2'),
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Elevation 4', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(MinglitSpacing.medium),
            child: Text('Card with elevation 4'),
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Elevation 8', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Card(
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.all(MinglitSpacing.medium),
            child: Text('Card with elevation 8'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inputs Section
// ---------------------------------------------------------------------------

class _InputsSection extends StatelessWidget {
  const _InputsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('MinglitTextField', style: theme.textTheme.titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Basic', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: 'Label',
          hintText: 'Normal input field',
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('With Helper Text', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: '이메일',
          hintText: 'example@minglit.com',
          helperText: '로그인에 사용할 이메일을 입력하세요',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Error State', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: '이메일',
          hintText: 'Error input',
          errorText: '올바른 이메일 형식이 아닙니다',
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Disabled', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: '비활성',
          hintText: 'Disabled input field',
          enabled: false,
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Password', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: '비밀번호',
          hintText: '비밀번호를 입력하세요',
          obscureText: true,
          prefixIcon: Icon(Icons.lock_outline),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('With Prefix & Suffix', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: '검색',
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.clear),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Multiline', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitTextField(
          label: '메모',
          hintText: '여러 줄 입력이 가능합니다',
          maxLines: 3,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs Section
// ---------------------------------------------------------------------------

class _DialogsSection extends StatelessWidget {
  const _DialogsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('AlertDialog', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Tap the button below to preview an AlertDialog.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
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
        const SizedBox(height: MinglitSpacing.large),
        Text('Destructive Dialog', style: theme.textTheme.titleMedium),
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// BottomSheet Section
// ---------------------------------------------------------------------------

class _BottomSheetSection extends StatelessWidget {
  const _BottomSheetSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('BottomSheet', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Tap the button below to preview a modal BottomSheet.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
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
// Badge / Tag Section
// ---------------------------------------------------------------------------

class _BadgeTagSection extends StatelessWidget {
  const _BadgeTagSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Chip (Badge/Tag)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Using the themed Chip widget as badge/tag components.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            Chip(
              label: const Text('Default'),
              backgroundColor: theme.chipTheme.backgroundColor,
            ),
            const Chip(
              label: Text('Primary'),
              backgroundColor: MinglitColors.primary,
              // ignore: minglit_no_hardcoded_colors -- catalog demo
              labelStyle: TextStyle(color: Colors.white),
            ),
            const Chip(
              label: Text('Success'),
              backgroundColor: MinglitColors.success,
              // ignore: minglit_no_hardcoded_colors -- catalog demo
              labelStyle: TextStyle(color: Colors.white),
            ),
            const Chip(
              label: Text('Warning'),
              backgroundColor: MinglitColors.warning,
              // ignore: minglit_no_hardcoded_colors -- catalog demo
              labelStyle: TextStyle(color: Colors.white),
            ),
            const Chip(
              label: Text('Error'),
              backgroundColor: MinglitColors.error,
              // ignore: minglit_no_hardcoded_colors -- catalog demo
              labelStyle: TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('MinglitTag', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Read-only color tags for categories and status indicators.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Checkbox Section
// ---------------------------------------------------------------------------

class _CheckboxSection extends StatefulWidget {
  const _CheckboxSection();

  @override
  State<_CheckboxSection> createState() => _CheckboxSectionState();
}

class _CheckboxSectionState extends State<_CheckboxSection> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Checkbox States', style: theme.textTheme.titleMedium),
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
// TabBar Section
// ---------------------------------------------------------------------------

class _TabBarSection extends StatelessWidget {
  const _TabBarSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('TabBar (2 tabs)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Tab A'),
                  Tab(text: 'Tab B'),
                ],
              ),
              SizedBox(
                height: 60,
                child: TabBarView(
                  children: [
                    Center(
                      child: Text(
                        'Content A',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child: Text(
                        'Content B',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('TabBar (3 tabs)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'First'),
                  Tab(text: 'Second'),
                  Tab(text: 'Third'),
                ],
              ),
              SizedBox(
                height: 60,
                child: TabBarView(
                  children: [
                    Center(
                      child: Text(
                        'Content 1',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child: Text(
                        'Content 2',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Center(
                      child: Text(
                        'Content 3',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Divider Section
// ---------------------------------------------------------------------------

class _DividerSection extends StatelessWidget {
  const _DividerSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('Divider (Light)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Text('Content above divider'),
        const Divider(),
        const Text('Content below divider'),
        const SizedBox(height: MinglitSpacing.large),
        Text('Divider (Custom Thickness)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Divider(thickness: 2),
        const SizedBox(height: MinglitSpacing.large),
        Text('Divider (Dark Background)', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          decoration: BoxDecoration(
            color: MinglitColorsDark.background,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: Column(
            children: [
              Text(
                'Content above',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MinglitColorsDark.textPrimary,
                ),
              ),
              const Divider(color: MinglitColorsDark.divider),
              Text(
                'Content below',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MinglitColorsDark.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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

// ---------------------------------------------------------------------------
// Layout Section
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

        // 4. 조합 예시
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
