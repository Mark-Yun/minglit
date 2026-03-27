import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Onboarding step guide for new partners.
/// Shows progress (2/4 or 3/4) and guides to next action.
class OnboardingStepGuide extends StatelessWidget {
  const OnboardingStepGuide({
    required this.hasParty,
    required this.partyName,
    required this.onCreateParty,
    required this.onCreateEvent,
    super.key,
  });

  final bool hasParty;
  final String? partyName;
  final VoidCallback onCreateParty;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = hasParty ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome header (only before party creation)
        if (!hasParty) ...[
          const SizedBox(height: MinglitSpacing.large),
          Center(
            child: Text(
              '🎊',
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 40),
            ),
          ),
          const SizedBox(height: MinglitSpacing.sm),
          Center(
            child: Text(
              '환영합니다!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Center(
            child: Text(
              '파트너 가입이 승인되었어요',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
        ],

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.xsmall,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '시작하기',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$progress/4 완료',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.xsmall2),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress / 4,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),

        // Steps card
        Card(
          child: Column(
            children: [
              // Step 1: Done
              _StepRow(
                number: 1,
                title: '파트너 가입',
                isDone: true,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const Divider(height: 1),
              // Step 2: Done
              _StepRow(
                number: 2,
                title: '계좌 등록',
                isDone: true,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const Divider(height: 1),
              // Step 3
              _StepRow(
                number: 3,
                title: '첫 파티 만들기',
                isDone: hasParty,
                isCurrent: !hasParty,
                subtitle: hasParty ? '방금 완료!' : '파티는 이벤트를 묶는 브랜드예요',
                theme: theme,
                colorScheme: colorScheme,
              ),
              const Divider(height: 1),
              // Step 4
              _StepRow(
                number: 4,
                title: '첫 이벤트 만들기',
                isDone: false,
                isCurrent: hasParty,
                isLocked: !hasParty,
                subtitle: hasParty ? '날짜·인원·티켓을 설정하세요' : '파티 생성 후 가능',
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),

        // Party card (after party creation)
        if (hasParty && partyName != null) ...[
          const SizedBox(height: MinglitSpacing.medium),
          Container(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(MinglitRadius.button),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MinglitRadius.input),
                  ),
                  child: Center(
                    child: Text(
                      '🎉',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partyName!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '이벤트 0개',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: MinglitSpacing.medium),

        // Main CTA
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: hasParty ? onCreateEvent : onCreateParty,
            icon: Icon(
              hasParty ? Icons.event_outlined : Icons.celebration_outlined,
              size: MinglitIconSize.small,
            ),
            label: Text(hasParty ? '첫 이벤트 만들기' : '첫 파티 만들기'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
          ),
        ),

        // How it works (only before party creation)
        if (!hasParty) ...[
          const SizedBox(height: MinglitSpacing.large),
          Container(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(MinglitRadius.input),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이렇게 진행돼요',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.sm),
                Row(
                  children: [
                    _FlowStep(
                      icon: '🎉',
                      label: '파티',
                      sub: '브랜드 설정',
                      theme: theme,
                    ),
                    _FlowArrow(theme: theme),
                    _FlowStep(
                      icon: '📅',
                      label: '이벤트',
                      sub: '날짜·인원',
                      theme: theme,
                    ),
                    _FlowArrow(theme: theme),
                    _FlowStep(
                      icon: '👥',
                      label: '신청',
                      sub: '승인·관리',
                      theme: theme,
                    ),
                    _FlowArrow(theme: theme),
                    _FlowStep(
                      icon: '💰',
                      label: '정산',
                      sub: '자동 입금',
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.isDone,
    required this.theme,
    required this.colorScheme,
    this.isCurrent = false,
    this.isLocked = false,
    this.subtitle,
  });

  final int number;
  final String title;
  final bool isDone;
  final bool isCurrent;
  final bool isLocked;
  final String? subtitle;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final opacity = isLocked ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        color: isCurrent ? colorScheme.primary.withValues(alpha: 0.05) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.sm,
        ),
        child: Row(
          children: [
            // Number/check circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone
                    ? MinglitColors.success
                    : isCurrent
                    ? colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? Icon(
                        Icons.check,
                        color: colorScheme.onPrimary,
                        size: 16,
                      )
                    : Text(
                        number.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCurrent ? colorScheme.onPrimary : null,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: MinglitSpacing.sm),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDone && subtitle == '방금 완료!'
                            ? MinglitColors.success
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isDone && subtitle == '방금 완료!'
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            if (isCurrent)
              Icon(
                Icons.chevron_right,
                color: colorScheme.primary,
                size: MinglitIconSize.small,
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.icon,
    required this.label,
    required this.sub,
    required this.theme,
  });
  final String icon;
  final String label;
  final String sub;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: MinglitSpacing.xxsmall),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            sub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
