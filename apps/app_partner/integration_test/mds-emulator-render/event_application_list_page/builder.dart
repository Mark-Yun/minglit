import 'package:app_partner/src/features/party/event/detail/event_application_list_page.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';

const _eventId = 'render-event-id';
const _groupWomen = 'render-group-women';
const _groupMen = 'render-group-men';
final _baseTime = DateTime(2026, 5, 30, 18);

enum _EventApplicationListScenario {
  defaultState,
  empty,
  asymmetric,
  overCapacity,
  fullCapacity,
  approvedTab,
  rejectedTab,
  refundTab,
  listTabEmpty,
}

class EventApplicationListPageBuilder
    extends MdsScreenBuilder<EventApplicationListPage> {
  EventApplicationListPageBuilder()
    : super(page: const EventApplicationListPage(eventId: _eventId));

  _EventApplicationListScenario _scenario =
      _EventApplicationListScenario.defaultState;

  EventApplicationListPageBuilder defaultState() {
    _scenario = _EventApplicationListScenario.defaultState;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder empty() {
    _scenario = _EventApplicationListScenario.empty;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder asymmetric() {
    _scenario = _EventApplicationListScenario.asymmetric;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder overCapacity() {
    _scenario = _EventApplicationListScenario.overCapacity;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder fullCapacity() {
    _scenario = _EventApplicationListScenario.fullCapacity;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder approvedTab() {
    _scenario = _EventApplicationListScenario.approvedTab;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder rejectedTab() {
    _scenario = _EventApplicationListScenario.rejectedTab;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder refundTab() {
    _scenario = _EventApplicationListScenario.refundTab;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  EventApplicationListPageBuilder listTabEmpty() {
    _scenario = _EventApplicationListScenario.listTabEmpty;
    // ignore: avoid_returning_this, fluent builder chain style
    return this;
  }

  @override
  Widget build() {
    final scenarioData = _buildScenario(_scenario);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((_) => null),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        notificationInitializerProvider.overrideWith((_) {}),
        eventApplicationBundleProvider(_eventId).overrideWith((ref) async {
          return (
            event: scenarioData.event,
            applications: scenarioData.applications,
            groupCounts: scenarioData.groupCounts,
          );
        }),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MinglitTheme.materialTheme,
        home: _AutoSelectTab(
          tabIndex: scenarioData.tabIndex,
          child: const EventApplicationListPage(eventId: _eventId),
        ),
      ),
    );
  }
}

class _AutoSelectTab extends StatefulWidget {
  const _AutoSelectTab({required this.tabIndex, required this.child});

  final int tabIndex;
  final Widget child;

  @override
  State<_AutoSelectTab> createState() => _AutoSelectTabState();
}

class _AutoSelectTabState extends State<_AutoSelectTab> {
  bool _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_applied || widget.tabIndex == 0) return;
    final controller = DefaultTabController.maybeOf(context);
    if (controller == null) return;
    _applied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.animateTo(widget.tabIndex, duration: Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ScenarioData {
  const _ScenarioData({
    required this.event,
    required this.applications,
    required this.groupCounts,
    required this.tabIndex,
  });

  final Event event;
  final List<EventApplication> applications;
  final List<Map<String, dynamic>> groupCounts;
  final int tabIndex;
}

_ScenarioData _buildScenario(_EventApplicationListScenario scenario) {
  final groups = _entryGroups();

  switch (scenario) {
    case _EventApplicationListScenario.defaultState:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 30),
        applications: [
          _application(
            id: 'pending-1',
            status: 'pending_review',
            groupId: _groupWomen,
            username: '루나',
            daysAgo: 0,
          ),
          _application(
            id: 'pending-2',
            status: 'pending',
            groupId: _groupMen,
            username: '민호',
            daysAgo: 1,
          ),
          _application(
            id: 'pending-3',
            status: 'pending_review',
            groupId: _groupWomen,
            username: '지우',
            daysAgo: 2,
          ),
          _application(
            id: 'paid-1',
            status: 'paid',
            groupId: _groupWomen,
            username: '하늘',
            daysAgo: 3,
            paidAt: _baseTime.subtract(const Duration(days: 3)),
            paymentAmount: 39000,
          ),
          _application(
            id: 'paid-2',
            status: 'paid',
            groupId: _groupMen,
            username: '도윤',
            daysAgo: 5,
            paidAt: _baseTime.subtract(const Duration(days: 5)),
            paymentAmount: 39000,
          ),
          _application(
            id: 'rejected-1',
            status: 'rejected',
            groupId: _groupMen,
            username: '유진',
            daysAgo: 4,
            rejectionReason: '입장 기준과 맞지 않습니다.',
          ),
          _application(
            id: 'refund-1',
            status: 'cancelled',
            groupId: _groupWomen,
            username: '세아',
            daysAgo: 1,
            refundedAt: _baseTime.subtract(const Duration(days: 1)),
            cancellationReason: '개인 일정으로 참석이 어렵습니다.',
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 6,
          menConfirmed: 5,
          womenTarget: 15,
          menTarget: 15,
        ),
        tabIndex: 0,
      );
    case _EventApplicationListScenario.empty:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 30),
        applications: const [],
        groupCounts: _groupCounts(
          womenConfirmed: 0,
          menConfirmed: 0,
          womenTarget: 15,
          menTarget: 15,
        ),
        tabIndex: 0,
      );
    case _EventApplicationListScenario.asymmetric:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 20),
        applications: [
          _application(
            id: 'pending-m-1',
            status: 'pending',
            groupId: _groupMen,
            username: '재훈',
            daysAgo: 0,
          ),
          _application(
            id: 'pending-m-2',
            status: 'pending_review',
            groupId: _groupMen,
            username: '윤호',
            daysAgo: 1,
          ),
          _application(
            id: 'paid-w-1',
            status: 'paid',
            groupId: _groupWomen,
            username: '소연',
            daysAgo: 3,
            paidAt: _baseTime.subtract(const Duration(days: 3)),
          ),
          _application(
            id: 'paid-w-2',
            status: 'paid',
            groupId: _groupWomen,
            username: '나연',
            daysAgo: 4,
            paidAt: _baseTime.subtract(const Duration(days: 4)),
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 7,
          menConfirmed: 3,
          womenTarget: 10,
          menTarget: 10,
        ),
        tabIndex: 0,
      );
    case _EventApplicationListScenario.overCapacity:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 5),
        applications: [
          _application(
            id: 'pending-w-1',
            status: 'pending_review',
            groupId: _groupWomen,
            username: '은지',
            daysAgo: 0,
          ),
          _application(
            id: 'pending-w-2',
            status: 'pending',
            groupId: _groupWomen,
            username: '가은',
            daysAgo: 1,
          ),
          _application(
            id: 'pending-m-1',
            status: 'pending_review',
            groupId: _groupMen,
            username: '태민',
            daysAgo: 0,
          ),
          _application(
            id: 'pending-m-2',
            status: 'pending',
            groupId: _groupMen,
            username: '현우',
            daysAgo: 2,
          ),
          _application(
            id: 'paid-w-1',
            status: 'paid',
            groupId: _groupWomen,
            username: '지아',
            daysAgo: 3,
            paidAt: _baseTime.subtract(const Duration(days: 3)),
          ),
          _application(
            id: 'paid-w-2',
            status: 'paid',
            groupId: _groupWomen,
            username: '유나',
            daysAgo: 4,
            paidAt: _baseTime.subtract(const Duration(days: 4)),
          ),
          _application(
            id: 'paid-m-1',
            status: 'paid',
            groupId: _groupMen,
            username: '준혁',
            daysAgo: 5,
            paidAt: _baseTime.subtract(const Duration(days: 5)),
          ),
          _application(
            id: 'paid-m-2',
            status: 'paid',
            groupId: _groupMen,
            username: '동현',
            daysAgo: 6,
            paidAt: _baseTime.subtract(const Duration(days: 6)),
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 2,
          menConfirmed: 2,
          womenTarget: 3,
          menTarget: 2,
        ),
        tabIndex: 0,
      );
    case _EventApplicationListScenario.fullCapacity:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 5),
        applications: [
          _application(
            id: 'pending-full-1',
            status: 'pending',
            groupId: _groupWomen,
            username: '수빈',
            daysAgo: 0,
          ),
          _application(
            id: 'pending-full-2',
            status: 'pending_review',
            groupId: _groupMen,
            username: '강민',
            daysAgo: 1,
          ),
          _application(
            id: 'paid-full-1',
            status: 'paid',
            groupId: _groupWomen,
            username: '연우',
            daysAgo: 3,
            paidAt: _baseTime.subtract(const Duration(days: 3)),
          ),
          _application(
            id: 'paid-full-2',
            status: 'paid',
            groupId: _groupWomen,
            username: '아린',
            daysAgo: 4,
            paidAt: _baseTime.subtract(const Duration(days: 4)),
          ),
          _application(
            id: 'paid-full-3',
            status: 'paid',
            groupId: _groupWomen,
            username: '다은',
            daysAgo: 5,
            paidAt: _baseTime.subtract(const Duration(days: 5)),
          ),
          _application(
            id: 'paid-full-4',
            status: 'paid',
            groupId: _groupMen,
            username: '시우',
            daysAgo: 6,
            paidAt: _baseTime.subtract(const Duration(days: 6)),
          ),
          _application(
            id: 'paid-full-5',
            status: 'paid',
            groupId: _groupMen,
            username: '지훈',
            daysAgo: 7,
            paidAt: _baseTime.subtract(const Duration(days: 7)),
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 3,
          menConfirmed: 2,
          womenTarget: 3,
          menTarget: 2,
        ),
        tabIndex: 0,
      );
    case _EventApplicationListScenario.approvedTab:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 20),
        applications: [
          _application(
            id: 'approved-paid-1',
            status: 'paid',
            groupId: _groupWomen,
            username: '시아',
            daysAgo: 1,
            paidAt: _baseTime.subtract(const Duration(days: 1)),
          ),
          _application(
            id: 'approved-paid-2',
            status: 'paid',
            groupId: _groupWomen,
            username: '주원',
            daysAgo: 2,
            paidAt: _baseTime.subtract(const Duration(days: 2)),
          ),
          _application(
            id: 'approved-paid-3',
            status: 'paid',
            groupId: _groupMen,
            username: '건우',
            daysAgo: 3,
            paidAt: _baseTime.subtract(const Duration(days: 3)),
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 4,
          menConfirmed: 3,
          womenTarget: 10,
          menTarget: 10,
        ),
        tabIndex: 1,
      );
    case _EventApplicationListScenario.rejectedTab:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 20),
        applications: [
          _application(
            id: 'rejected-1',
            status: 'rejected',
            groupId: _groupWomen,
            username: '하린',
            daysAgo: 1,
            rejectionReason: '연령 기준을 충족하지 않습니다.',
          ),
          _application(
            id: 'rejected-2',
            status: 'rejected',
            groupId: _groupMen,
            username: '서준',
            daysAgo: 2,
            rejectionReason: '필수 인증이 확인되지 않았습니다.',
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 0,
          menConfirmed: 0,
          womenTarget: 10,
          menTarget: 10,
        ),
        tabIndex: 2,
      );
    case _EventApplicationListScenario.refundTab:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 20),
        applications: [
          _application(
            id: 'refund-1',
            status: 'cancelled',
            groupId: _groupWomen,
            username: '보라',
            daysAgo: 1,
            refundedAt: _baseTime.subtract(const Duration(days: 1)),
            cancellationReason: '건강상 이유로 참여가 어렵습니다.',
          ),
          _application(
            id: 'refund-2',
            status: 'cancelled',
            groupId: _groupMen,
            username: '지성',
            daysAgo: 3,
            refundedAt: _baseTime.subtract(const Duration(days: 3)),
            cancellationReason: '개인 사정으로 일정 취소 요청',
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 0,
          menConfirmed: 0,
          womenTarget: 10,
          menTarget: 10,
        ),
        tabIndex: 3,
      );
    case _EventApplicationListScenario.listTabEmpty:
      return _ScenarioData(
        event: _buildEvent(entryGroups: groups, maxParticipants: 20),
        applications: [
          _application(
            id: 'only-pending-1',
            status: 'pending_review',
            groupId: _groupWomen,
            username: '하민',
            daysAgo: 0,
          ),
          _application(
            id: 'only-pending-2',
            status: 'pending',
            groupId: _groupMen,
            username: '유찬',
            daysAgo: 1,
          ),
        ],
        groupCounts: _groupCounts(
          womenConfirmed: 0,
          menConfirmed: 0,
          womenTarget: 10,
          menTarget: 10,
        ),
        tabIndex: 1,
      );
  }
}

Event _buildEvent({
  required List<EntryGroup> entryGroups,
  required int maxParticipants,
}) {
  return Event(
    id: _eventId,
    partyId: 'render-party-id',
    title: '금요일 밍글 파티',
    startTime: _baseTime.add(const Duration(days: 2)),
    endTime: _baseTime.add(const Duration(days: 2, hours: 3)),
    createdAt: _baseTime.subtract(const Duration(days: 30)),
    updatedAt: _baseTime,
    maxParticipants: maxParticipants,
    location: Location(
      id: 'render-location-id',
      partnerId: 'render-partner-id',
      name: '밍글릿 강남점',
      address: '서울 강남구 테헤란로 123',
      createdAt: _baseTime.subtract(const Duration(days: 90)),
      updatedAt: _baseTime,
    ),
    entryGroups: entryGroups,
  );
}

List<EntryGroup> _entryGroups() => const [
  EntryGroup(
    id: _groupWomen,
    eventId: _eventId,
    label: '여성 그룹',
    gender: 'female',
    birthYearMin: 1995,
    birthYearMax: 2004,
    requiredVerificationIds: ['identity_verification'],
  ),
  EntryGroup(
    id: _groupMen,
    eventId: _eventId,
    label: '남성 그룹',
    gender: 'male',
    birthYearMin: 1992,
    birthYearMax: 2001,
  ),
];

List<Map<String, dynamic>> _groupCounts({
  required int womenConfirmed,
  required int menConfirmed,
  required int womenTarget,
  required int menTarget,
}) => [
  {
    'entry_group_id': _groupWomen,
    'participant_count': womenConfirmed,
    'target_capacity': womenTarget,
  },
  {
    'entry_group_id': _groupMen,
    'participant_count': menConfirmed,
    'target_capacity': menTarget,
  },
];

EventApplication _application({
  required String id,
  required String status,
  required String groupId,
  required String username,
  required int daysAgo,
  int birthYear = 1998,
  int? paymentAmount,
  DateTime? paidAt,
  DateTime? refundedAt,
  String? rejectionReason,
  String? cancellationReason,
}) {
  final createdAt = _baseTime.subtract(Duration(days: daysAgo + 7));
  final updatedAt = _baseTime.subtract(Duration(days: daysAgo));
  final ticketId = 'render-ticket-$groupId-$id';
  return EventApplication(
    id: id,
    eventId: _eventId,
    ticketId: ticketId,
    userId: 'render-user-$id',
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    paymentAmount: paymentAmount,
    paidAt: paidAt,
    refundedAt: refundedAt,
    rejectionReason: rejectionReason,
    cancellationReason: cancellationReason,
    user: UserProfile(
      id: 'render-user-$id',
      name: '사용자-$id',
      username: username,
      birthYear: birthYear,
    ),
    ticket: Ticket(
      id: ticketId,
      name: '입장권',
      createdAt: _baseTime.subtract(const Duration(days: 10)),
      updatedAt: _baseTime,
      eventId: _eventId,
      targetEntryGroupIds: [groupId],
    ),
  );
}
