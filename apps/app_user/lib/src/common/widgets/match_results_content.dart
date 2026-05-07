import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Shared widget used by both home (EventNowBottomSheet) and
// event/admission (eventEndedWithResults CTA).
class MatchResultsContent extends ConsumerWidget {
  const MatchResultsContent({required this.activeEvent, super.key});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final matchesAsync = ref.watch(myMatchesProvider(event.id));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(),
          const SizedBox(height: MinglitSpacing.xlarge),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: MinglitColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: MinglitColors.background,
              size: 36,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '매칭 결과',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
          matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) return _buildEmptyResult(theme);
              return _buildMatchList(theme, matches);
            },
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: MinglitCircularProgressIndicator()),
            ),
            error: (_, _) => _buildEmptyResult(theme),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }

  Widget _buildEmptyResult(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xlarge),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 48,
            color: MinglitColors.textSecondary.withValues(
              alpha: MinglitOpacity.strong,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '이번엔 아쉽지만, 다음 기회에!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(ThemeData theme, List<MatchPair> matches) {
    return Column(
      children: [
        Text(
          '${matches.length}명과 매칭되었어요!',
          style: theme.textTheme.titleSmall?.copyWith(
            color: MinglitColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        for (final match in matches) ...[
          _MatchResultCard(match: match),
          const SizedBox(height: MinglitSpacing.small),
        ],
      ],
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard({required this.match});

  final MatchPair match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: MinglitColors.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(
          color: MinglitColors.primary.withValues(alpha: MinglitOpacity.muted),
        ),
      ),
      child: Row(
        children: [
          // Fix #1936: MinglitAvatarImage handles caching + error fallback
          MinglitAvatarImage(
            radius: 24,
            url: match.partnerProfileImage,
            backgroundColor: MinglitColors.primary.withValues(
              alpha: MinglitOpacity.highlight,
            ),
            fallbackIconColor: MinglitColors.primary.withValues(
              alpha: MinglitOpacity.separator,
            ),
          ),
          const SizedBox(width: MinglitSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.partnerName ?? '알 수 없음',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (match.partnerContact != null) ...[
                  const SizedBox(height: MinglitSpacing.xxsmall),
                  Text(
                    // Fix #1925: mask phone number to prevent PII exposure in UI
                    // (개인정보보호법 §24 — phone numbers are sensitive PII)
                    _maskPhone(match.partnerContact!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MinglitColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.favorite,
            color: MinglitColors.primary,
            size: MinglitIconSize.small,
          ),
        ],
      ),
    );
  }
}

/// Fix #1925: masks middle digits of a Korean phone number to protect PII.
/// Handles both raw (+821012345678) and local (01012345678) formats.
/// Result: 010-****-5678
String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  // Normalize country code: +82XX... → 0XX...
  final local = digits.startsWith('82') && digits.length > 10
      ? '0${digits.substring(2)}'
      : digits;
  if (local.length == 11) {
    return '${local.substring(0, 3)}-****-${local.substring(7)}';
  }
  if (local.length == 10) {
    return '${local.substring(0, 3)}-***-${local.substring(6)}';
  }
  // Fallback: never expose full input — short numbers (<=4 digits) are fully masked
  if (local.length <= 4) return '***-****-****';
  return '***-****-${local.substring(local.length - 4)}';
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: MinglitColors.textSecondary.withValues(
          alpha: MinglitOpacity.muted,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
