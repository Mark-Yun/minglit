import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_tickets_controller.g.dart';

class MyTicketsState {
  const MyTicketsState({
    required this.upcoming,
    required this.past,
    required this.todayEvent,
  });

  final List<EventApplication> upcoming;
  final List<EventApplication> past;
  final EventApplication? todayEvent;
}

@riverpod
class MyTicketsController extends _$MyTicketsController {
  @override
  FutureOr<MyTicketsState> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const MyTicketsState(
        upcoming: [],
        past: [],
        todayEvent: null,
      );
    }

    final repository = ref.watch(eventRepositoryProvider);
    final tickets = await repository.getMyTickets(user.id);
    return _categorize(tickets);
  }

  MyTicketsState _categorize(List<EventApplication> tickets) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final upcoming = <EventApplication>[];
    final past = <EventApplication>[];
    EventApplication? todayEvent;

    for (final ticket in tickets) {
      final startTime = ticket.event?.startTime;
      if (startTime == null) {
        past.add(ticket);
        continue;
      }

      if (startTime.isAfter(now)) {
        upcoming.add(ticket);

        // 오늘 시작하는 이벤트 중 가장 임박한 것
        if (!startTime.isBefore(todayStart) && startTime.isBefore(todayEnd)) {
          if (todayEvent == null ||
              startTime.isBefore(todayEvent.event!.startTime)) {
            todayEvent = ticket;
          }
        }
      } else {
        past.add(ticket);

        // 오늘 시작했지만 이미 시작 시간이 지난 경우도 todayEvent 후보
        if (!startTime.isBefore(todayStart) && startTime.isBefore(todayEnd)) {
          if (todayEvent == null ||
              startTime.isAfter(todayEvent.event!.startTime)) {
            todayEvent = ticket;
          }
        }
      }
    }

    // upcoming: 가까운 순 (ASC)
    upcoming.sort(
      (a, b) => a.event!.startTime.compareTo(b.event!.startTime),
    );

    // past: 최근 종료 순 (DESC)
    past.sort((a, b) {
      final aTime = a.event?.startTime;
      final bTime = b.event?.startTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return MyTicketsState(
      upcoming: upcoming,
      past: past,
      todayEvent: todayEvent,
    );
  }
}
