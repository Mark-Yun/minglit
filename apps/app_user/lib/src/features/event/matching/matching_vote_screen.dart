import 'package:app_user/src/features/event/matching/matching_vote_content.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MatchingVoteScreen extends StatelessWidget {
  const MatchingVoteScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '매칭 투표'),
      body: MatchingVoteContent(eventId: eventId),
    );
  }
}
