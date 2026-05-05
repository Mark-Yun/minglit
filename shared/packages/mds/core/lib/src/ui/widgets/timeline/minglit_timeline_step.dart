import 'package:flutter/widgets.dart';

/// Visual tone for a [MinglitTimelineStep] dot and title.
enum TimelineTone { success, progress, error, neutral, muted }

/// Data model for a single step in a [MinglitTimeline].
///
/// [tone] controls dot/title color semantics.
/// [pulsing] is orthogonal to tone — triggers the 1.4s opacity+scale animation.
/// [trailing] renders inline to the right of [title] (timestamps, amounts, badges).
/// [child] renders below the heading row (reason text, collapsible, CTA, etc.).
class MinglitTimelineStep {
  const MinglitTimelineStep({
    required this.tone,
    required this.title,
    this.pulsing = false,
    this.trailing,
    this.child,
  });

  final TimelineTone tone;
  final bool pulsing;
  final String title;
  final Widget? trailing;
  final Widget? child;
}
