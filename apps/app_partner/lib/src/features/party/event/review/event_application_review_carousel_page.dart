import 'package:flutter/material.dart';

// Fix #2126: stub — full carousel page is issue #2127
class EventApplicationReviewCarouselPage extends StatelessWidget {
  const EventApplicationReviewCarouselPage({
    required this.eventId,
    this.startApplicationId,
    this.groupId,
    super.key,
  });
  final String eventId;
  final String? startApplicationId;
  final String? groupId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('심사')),
      body: const Center(child: Text('심사 carousel — 준비 중')),
    );
  }
}
