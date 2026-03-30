import 'package:app_user/src/features/event/matching/widgets/matching_vote_content.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

export 'package:app_user/src/features/event/matching/widgets/matching_vote_content.dart';

/// Full-screen matching vote page with Scaffold + AppBar.
class MatchingVoteScreen extends ConsumerWidget {
  const MatchingVoteScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '매칭 투표'),
      body: MatchingVoteContent(eventId: eventId),
    );
  }
}
