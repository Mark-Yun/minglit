import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_detail_view.g.dart';

/// A detailed view of a Party.
class PartyDetailView extends ConsumerWidget {
  const PartyDetailView({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(),
                  const SizedBox(height: 32),
                  const Text(
                    '다가오는 일정',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildEventList(ref),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          party.title,
          style: const TextStyle(
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (party.imageUrl != null)
              Image.network(party.imageUrl!, fit: BoxFit.cover)
            else
              Container(color: Colors.orange[100]),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    // Assuming description is simple text for now (DB has jsonb)
    final descMap = party.description;
    final text = descMap?['text'] as String? ?? '파티 소개가 없습니다.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 16),
        if (party.contactOptions['phone'] != null)
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                party.contactOptions['phone'] as String,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEventList(WidgetRef ref) {
    final eventsAsync = ref.watch(partyEventsProvider(partyId: party.id));

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('예정된 일정이 없습니다.')),
          );
        }
        return Column(children: events.map(_buildEventCard).toList());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading events: $e'),
    );
  }

  Widget _buildEventCard(Event event) {
    final dateFormat = DateFormat('MM월 dd일 (E) HH:mm', 'ko_KR');
    final dateStr = dateFormat.format(event.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          event.title ?? '정기 파티',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                const SizedBox(width: 6),
                Text(dateStr),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${event.currentParticipants} / ${event.maxParticipants}명',
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text('예매'),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {}, // TODO(dev): Share
                child: const Text('공유하기'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주최자에게 문의하기 (TBD)')),
                  );
                },
                child: const Text('문의하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider to fetch upcoming events for this party.
@riverpod
Future<List<Event>> partyEvents(Ref ref, {required String partyId}) {
  return ref.read(partyRepositoryProvider).getEventsByPartyId(partyId);
}
