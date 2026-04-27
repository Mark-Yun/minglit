import 'package:flutter/material.dart';
import 'package:mds/mds.dart';
import 'package:widgetbook/widgetbook.dart';

import 'fixtures/mock_events.dart';

void main() => runApp(const MdsStorybookApp());

class MdsStorybookApp extends StatelessWidget {
  const MdsStorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // Apply Minglit theme so all stories render with the correct tokens.
      addons: [
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: MinglitTheme.materialTheme),
            WidgetbookTheme(name: 'Dark', data: MinglitTheme.materialThemeDark),
          ],
          initialTheme: WidgetbookTheme(
            name: 'Light',
            data: MinglitTheme.materialTheme,
          ),
        ),
      ],
      directories: [
        // ──────────────────────────────────────────────
        // TOKENS
        // ──────────────────────────────────────────────
        WidgetbookCategory(
          name: 'Tokens',
          children: [
            WidgetbookComponent(
              name: 'Colors',
              useCases: [
                WidgetbookUseCase(
                  name: 'Light palette',
                  builder: (context) => const _ColorsStory(),
                ),
                WidgetbookUseCase(
                  name: 'Dark palette',
                  builder: (context) => const _DarkColorsStory(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Spacing',
              useCases: [
                WidgetbookUseCase(
                  name: 'Scale',
                  builder: (context) => const _SpacingStory(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Radius',
              useCases: [
                WidgetbookUseCase(
                  name: 'Scale',
                  builder: (context) => const _RadiusStory(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Typography',
              useCases: [
                WidgetbookUseCase(
                  name: 'Text styles',
                  builder: (context) => const _TypographyStory(),
                ),
              ],
            ),
          ],
        ),

        // ──────────────────────────────────────────────
        // WIDGETS
        // ──────────────────────────────────────────────
        WidgetbookCategory(
          name: 'Widgets',
          children: [
            // ── Buttons ────────────────────────────────
            WidgetbookComponent(
              name: 'Buttons',
              useCases: [
                WidgetbookUseCase(
                  name: 'MinglitButton / primary',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MinglitButton(label: '참가하기', onPressed: () {}),
                          const SizedBox(height: MinglitSpacing.small),
                          const MinglitButton(label: '비활성'),
                          const SizedBox(height: MinglitSpacing.small),
                          const MinglitButton(label: '로딩 중', isLoading: true),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitButton / secondary',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MinglitButton.secondary(
                            label: '취소',
                            onPressed: () {},
                          ),
                          const SizedBox(height: MinglitSpacing.small),
                          const MinglitButton.secondary(label: '비활성'),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitButton / destructive',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: MinglitButton.destructive(
                        label: '삭제하기',
                        icon: Icons.delete_outline,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitButton / sizes',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MinglitButton(
                            label: 'Large (default)',
                            size: MinglitButtonSize.large,
                            onPressed: () {},
                          ),
                          const SizedBox(height: MinglitSpacing.small),
                          MinglitButton(
                            label: 'Medium',
                            size: MinglitButtonSize.medium,
                            onPressed: () {},
                          ),
                          const SizedBox(height: MinglitSpacing.small),
                          MinglitButton(
                            label: 'Small',
                            size: MinglitButtonSize.small,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitChip',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: const Wrap(
                        spacing: MinglitSpacing.small,
                        runSpacing: MinglitSpacing.small,
                        children: [
                          MinglitChip(label: 'Default'),
                          MinglitChip(
                            label: 'With Icon',
                            icon: Icons.music_note,
                          ),
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
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitFilterChip',
                  builder: (context) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(MinglitSpacing.medium),
                      child: _FilterChipStory(),
                    ),
                  ),
                ),
              ],
            ),

            // ── Inputs ─────────────────────────────────
            WidgetbookComponent(
              name: 'Inputs',
              useCases: [
                WidgetbookUseCase(
                  name: 'MinglitTextField / default',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: MinglitTextField(
                        label: '이름',
                        hintText: '홍길동',
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitTextField / error',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: MinglitTextField(
                        label: '이메일',
                        hintText: 'example@minglit.com',
                        errorText: '올바른 이메일 형식이 아닙니다',
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitTextField / disabled',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: MinglitTextField(
                        label: '비활성 필드',
                        hintText: '입력 불가',
                        enabled: false,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitTextField / with icons',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: MinglitTextField(
                        label: '검색',
                        hintText: '이벤트 검색...',
                        prefixIcon: const Icon(Icons.search),
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Cards ──────────────────────────────────
            WidgetbookComponent(
              name: 'Cards',
              useCases: [
                WidgetbookUseCase(
                  name: 'MinglitContentCard / default',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MinglitContentCard(child: Text('기본 카드')),
                          SizedBox(height: MinglitSpacing.small),
                          MinglitContentCard(
                            highlighted: true,
                            child: Text('highlighted 카드 (primary 보더)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitTag / sizes & colors',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: MinglitSpacing.small,
                            runSpacing: MinglitSpacing.small,
                            children: [
                              MinglitTag(
                                label: '음악',
                                color: MinglitColors.primary,
                              ),
                              MinglitTag(
                                label: '승인',
                                color: MinglitColors.success,
                              ),
                              MinglitTag(
                                label: '대기',
                                color: MinglitColors.warning,
                              ),
                              MinglitTag(
                                label: '취소',
                                color: MinglitColors.error,
                              ),
                              MinglitTag(
                                label: '카테고리',
                                color: MinglitColors.primary,
                                icon: Icons.category,
                              ),
                            ],
                          ),
                          SizedBox(height: MinglitSpacing.medium),
                          Wrap(
                            spacing: MinglitSpacing.small,
                            runSpacing: MinglitSpacing.small,
                            children: [
                              MinglitTag(
                                label: '소형',
                                color: MinglitColors.primary,
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
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitBadge',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: const Wrap(
                        spacing: MinglitSpacing.small,
                        runSpacing: MinglitSpacing.small,
                        children: [
                          MinglitBadge(
                            label: '승인됨',
                            color: MinglitColors.success,
                          ),
                          MinglitBadge(
                            label: '대기',
                            color: MinglitColors.warning,
                          ),
                          MinglitBadge(
                            label: '거절',
                            color: MinglitColors.error,
                          ),
                          MinglitBadge(
                            label: '정산',
                            color: MinglitColors.primary,
                          ),
                          MinglitBadge(
                            label: 'compact',
                            color: MinglitColors.primary,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitParticipantGauge',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MinglitParticipantGauge(current: 3, max: 20),
                          SizedBox(height: MinglitSpacing.small),
                          MinglitParticipantGauge(current: 10, max: 20),
                          SizedBox(height: MinglitSpacing.small),
                          MinglitParticipantGauge(current: 20, max: 20),
                          SizedBox(height: MinglitSpacing.small),
                          MinglitParticipantGauge(current: 0, max: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Feedback ───────────────────────────────
            WidgetbookComponent(
              name: 'Feedback',
              useCases: [
                WidgetbookUseCase(
                  name: 'MinglitEmptyState / default',
                  builder: (context) => const Center(
                    child: MinglitContentCard(
                      child: MinglitEmptyState(
                        title: '저장된 항목이 없습니다',
                        subtitle: '새로운 항목을 추가해보세요',
                        actionLabel: '새로 만들기',
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitEmptyState / no action',
                  builder: (context) => const Center(
                    child: MinglitContentCard(
                      child: MinglitEmptyState(
                        title: '검색 결과가 없습니다',
                        subtitle: '다른 키워드로 검색해보세요',
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitErrorState',
                  builder: (context) => const Center(
                    child: MinglitContentCard(
                      child: MinglitErrorState(
                        title: '데이터를 불러올 수 없습니다',
                        subtitle: '네트워크 연결을 확인해주세요',
                      ),
                    ),
                  ),
                ),
                // TODO: MinglitAlert / MinglitDialog deferred — these require
                // Navigator context + async showDialog calls which don't render
                // well as static UseCase snapshots. Consider Patterns section
                // or a dedicated overlay story with a trigger button in a
                // follow-up PR.
              ],
            ),

            // ── Layout ─────────────────────────────────
            WidgetbookComponent(
              name: 'Layout',
              useCases: [
                WidgetbookUseCase(
                  name: 'MinglitSection',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MinglitSection(
                          title: '참여 현황',
                          child: Text('섹션 콘텐츠'),
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
                      ],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitKeyValueRow',
                  builder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      child: const MinglitContentCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MinglitKeyValueRow(
                              label: '총 매출',
                              value: '₩420,000',
                            ),
                            MinglitKeyValueRow(
                              label: '수수료',
                              value: '-₩42,000',
                            ),
                            Divider(),
                            MinglitKeyValueRow(
                              label: '정산금',
                              value: '₩378,000',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitSectionDivider',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'thick (8px)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Text('위'),
                        const MinglitSectionDivider.thick(),
                        const Text('아래'),
                        const SizedBox(height: MinglitSpacing.large),
                        Text(
                          'thin (1px)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Text('위'),
                        const MinglitSectionDivider.thin(),
                        const Text('아래'),
                      ],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitListTile',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MinglitListTile(title: '기본 타일'),
                        const SizedBox(height: MinglitSpacing.small),
                        const MinglitListTile(
                          title: '홍길동',
                          subtitle: '파트너 매니저',
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        MinglitListTile(
                          title: 'Trailing icon',
                          subtitle: '탭 가능한 타일',
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
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitContentLayout',
                  builder: (context) => const SingleChildScrollView(
                    child: MinglitContentLayout(
                      topPadding: MinglitSpacing.medium,
                      bottomPadding: MinglitSpacing.medium,
                      showDividers: true,
                      sections: [
                        MinglitSection(
                          title: '기본 정보',
                          child: Text('섹션 1'),
                        ),
                        MinglitSection(
                          title: '참여 현황',
                          child: Text('섹션 2'),
                        ),
                        MinglitSection(
                          title: '위치',
                          child: Text('섹션 3'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Loading ────────────────────────────────
            WidgetbookComponent(
              name: 'Loading',
              useCases: [
                WidgetbookUseCase(
                  name: 'MinglitSkeleton',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MinglitSkeleton(width: 200, height: 20),
                        const SizedBox(height: MinglitSpacing.small),
                        const MinglitSkeleton(width: 150, height: 20),
                        const SizedBox(height: MinglitSpacing.small),
                        MinglitSkeleton(
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(MinglitRadius.card),
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        MinglitSkeleton(
                          width: double.infinity,
                          height: 120,
                          borderRadius: BorderRadius.circular(MinglitRadius.card),
                        ),
                      ],
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitCircularProgressIndicator',
                  builder: (context) => const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                  ),
                ),
                WidgetbookUseCase(
                  name: 'MinglitLinearProgressIndicator',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Indeterminate',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        const MinglitLinearProgressIndicator(),
                        const SizedBox(height: MinglitSpacing.medium),
                        Text(
                          '30%',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        const MinglitLinearProgressIndicator(value: 0.3),
                        const SizedBox(height: MinglitSpacing.medium),
                        Text(
                          '100% (success)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        const MinglitLinearProgressIndicator(
                          value: 1,
                          color: MinglitColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
                // TODO: MinglitAsyncValueWidget deferred — requires a live
                // AsyncValue<T> (Riverpod) which needs a ProviderScope. Will
                // add in follow-up once storybook has flutter_riverpod wired.
              ],
            ),

            // ── Extras ─────────────────────────────────
            WidgetbookComponent(
              name: 'Extras',
              useCases: [
                WidgetbookUseCase(
                  name: 'Event card (composed)',
                  builder: (context) => SingleChildScrollView(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Column(
                      children: [
                        for (final event in sampleEvents)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: MinglitSpacing.small,
                            ),
                            child: MinglitContentCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: MinglitSpacing.xsmall),
                                  Text(event.subtitle),
                                  const SizedBox(height: MinglitSpacing.small),
                                  Row(
                                    children: [
                                      MinglitTag(
                                        label: event.categoryLabel,
                                        color: MinglitColors.primary,
                                        size: MinglitTagSize.small,
                                      ),
                                      const Spacer(),
                                      MinglitParticipantGauge(
                                        current: event.currentParticipants,
                                        max: event.maxParticipants,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Token story helper widgets
// ──────────────────────────────────────────────────────────────────────────────

class _ColorsStory extends StatelessWidget {
  const _ColorsStory();

  @override
  Widget build(BuildContext context) {
    const colors = <String, Color>{
      'background': MinglitColors.background,
      'primary': MinglitColors.primary,
      'secondary': MinglitColors.secondary,
      'tertiary': MinglitColors.tertiary,
      'surface': MinglitColors.surface,
      'error': MinglitColors.error,
      'textPrimary': MinglitColors.textPrimary,
      'textSecondary': MinglitColors.textSecondary,
      'success': MinglitColors.success,
      'warning': MinglitColors.warning,
      'scrim': MinglitColors.scrim,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Wrap(
        spacing: MinglitSpacing.small,
        runSpacing: MinglitSpacing.small,
        children: [
          for (final e in colors.entries)
            _ColorSwatch(name: e.key, color: e.value),
        ],
      ),
    );
  }
}

class _DarkColorsStory extends StatelessWidget {
  const _DarkColorsStory();

  @override
  Widget build(BuildContext context) {
    const colors = <String, Color>{
      'background': MinglitColorsDark.background,
      'surface': MinglitColorsDark.surface,
      'textPrimary': MinglitColorsDark.textPrimary,
      'textSecondary': MinglitColorsDark.textSecondary,
      'primary': MinglitColorsDark.primary,
      'secondary': MinglitColorsDark.secondary,
      'tertiary': MinglitColorsDark.tertiary,
      'error': MinglitColorsDark.error,
      'divider': MinglitColorsDark.divider,
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: MinglitColorsDark.background,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        child: Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            for (final e in colors.entries)
              _ColorSwatch(name: e.key, color: e.value, darkBg: true),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.name,
    required this.color,
    this.darkBg = false,
  });

  final String name;
  final Color color;
  final bool darkBg;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use -- simplest hex conversion available
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

class _SpacingStory extends StatelessWidget {
  const _SpacingStory();

  @override
  Widget build(BuildContext context) {
    const spacings = <String, double>{
      'zero (0)': MinglitSpacing.zero,
      'xxsmall (2)': MinglitSpacing.xxsmall,
      'xsmall (4)': MinglitSpacing.xsmall,
      'xsmall2 (6)': MinglitSpacing.xsmall2,
      'small (8)': MinglitSpacing.small,
      'sm (12)': MinglitSpacing.sm,
      'medium (16)': MinglitSpacing.medium,
      'large (24)': MinglitSpacing.large,
      'xlarge (32)': MinglitSpacing.xlarge,
    };
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        for (final e in spacings.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (e.value > 0)
                  Container(
                    width: e.value,
                    height: 24,
                    decoration: BoxDecoration(
                      color: MinglitColors.primary.withAlpha(180),
                      borderRadius: BorderRadius.circular(MinglitRadius.small),
                    ),
                  ),
                const SizedBox(width: MinglitSpacing.small),
                Text(
                  '${e.value.toInt()}px',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MinglitColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RadiusStory extends StatelessWidget {
  const _RadiusStory();

  @override
  Widget build(BuildContext context) {
    const radii = <String, double>{
      'small (8)': MinglitRadius.small,
      'input (12)': MinglitRadius.input,
      'button (12)': MinglitRadius.button,
      'card (16)': MinglitRadius.card,
    };
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        for (final e in radii.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: MinglitColors.primary.withAlpha(30),
                    border: Border.all(color: MinglitColors.primary),
                    borderRadius: BorderRadius.circular(e.value),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${e.value.toInt()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypographyStory extends StatelessWidget {
  const _TypographyStory();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Only show slots defined in MinglitTheme (omit M3-default displayMedium/headlineLarge).
    final styles = <String, TextStyle?>{
      'displayLarge': textTheme.displayLarge,
      'displaySmall': textTheme.displaySmall,
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
      separatorBuilder: (_, __) => const Divider(),
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
                'size: ${style?.fontSize ?? "inherit"} / '
                'weight: ${style?.fontWeight ?? "inherit"}',
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

// Stateful helper for the filter chip interactive story.
class _FilterChipStory extends StatefulWidget {
  const _FilterChipStory();

  @override
  State<_FilterChipStory> createState() => _FilterChipStoryState();
}

class _FilterChipStoryState extends State<_FilterChipStory> {
  bool _firstSelected = true;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MinglitSpacing.small,
      runSpacing: MinglitSpacing.small,
      children: [
        MinglitFilterChip(
          label: '최신순',
          isSelected: _firstSelected,
          icon: Icons.sort,
          onTap: () => setState(() => _firstSelected = true),
        ),
        MinglitFilterChip(
          label: '인기순',
          isSelected: !_firstSelected,
          onTap: () => setState(() => _firstSelected = false),
        ),
      ],
    );
  }
}
