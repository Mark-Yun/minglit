import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ---------------------------------------------------------------------------
// Phase 5: Ended — review + next event suggestion
// ---------------------------------------------------------------------------

// Fix #665: ENDED 상태에서 별점 리뷰 UI + 리뷰 CTA
class EndedContent extends StatelessWidget {
  const EndedContent({required this.activeEvent, super.key});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context) {
    final event = activeEvent.event;
    final theme = Theme.of(context);

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
            decoration: BoxDecoration(
              color: MinglitColors.textSecondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              color: MinglitColors.textSecondary,
              size: 36,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '이벤트가 종료되었어요',
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
          Text(
            '이벤트는 어떠셨나요?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          const _StarRatingRow(),
          const SizedBox(height: MinglitSpacing.xlarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('리뷰 작성하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.medium,
                ),
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}

class _StarRatingRow extends StatefulWidget {
  const _StarRatingRow();

  @override
  State<_StarRatingRow> createState() => _StarRatingRowState();
}

class _StarRatingRowState extends State<_StarRatingRow> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => setState(() => _rating = starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= _rating ? Icons.star : Icons.star_border,
              size: 40,
              color: starIndex <= _rating
                  ? MinglitColors.secondary
                  : MinglitColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        );
      }),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: MinglitColors.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
