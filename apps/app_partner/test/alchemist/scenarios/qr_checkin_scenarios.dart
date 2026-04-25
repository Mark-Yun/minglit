import 'package:app_partner/src/features/checkin/checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/checkin_participant.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_controller.dart';
import 'package:app_partner/src/features/checkin/manual/manual_checkin_sheet.dart';
import 'package:app_partner/src/features/checkin/stats/entry_group_checkin_stats_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/checkin_scanner_overlay.dart';
import 'package:app_partner/src/features/checkin/widgets/entry_group_row.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'partner_screenshot_scenario.dart';

// ---------------------------------------------------------------------------
// Fake controllers for golden snapshots
// ---------------------------------------------------------------------------

class _FakeManualCheckinController extends ManualCheckinController {
  _FakeManualCheckinController(this._participants);
  final List<CheckinParticipant> _participants;

  @override
  Future<List<CheckinParticipant>> build(String eventId) async => _participants;

  @override
  Future<String> checkin(String ticketId) async => 'success';
}

class _ErrorManualCheckinController extends ManualCheckinController {
  @override
  Future<List<CheckinParticipant>> build(String eventId) async {
    throw Exception('네트워크 연결을 확인해주세요');
  }

  @override
  Future<String> checkin(String ticketId) async => 'error';
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _kEventId = 'golden-event';

const _participantA = CheckinParticipant(
  id: 'ep-1',
  ticketId: 'tk-1',
  name: '김민지',
  phoneLast4: '1234',
  status: 'ticket_issued',
);

const _participantB = CheckinParticipant(
  id: 'ep-2',
  ticketId: 'tk-2',
  name: '박재훈',
  phoneLast4: '5678',
  status: 'checked_in',
);

const _groupLow = EntryGroupCheckinStats(
  id: 'g-1',
  label: 'A구역',
  total: 100,
  checkedIn: 30,
);

const _groupHigh = EntryGroupCheckinStats(
  id: 'g-2',
  label: 'B구역',
  total: 100,
  checkedIn: 95,
);

const _groupMid = EntryGroupCheckinStats(
  id: 'g-3',
  label: 'C구역',
  total: 80,
  checkedIn: 55,
);

// ---------------------------------------------------------------------------
// Wrapper widgets
// ---------------------------------------------------------------------------

/// 체크인 결과 배너 — 고정 너비 카드로 골든 렌더.
class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.state, required this.brightness});
  final CheckinState state;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark
          ? MinglitTheme.materialThemeDark
          : MinglitTheme.materialTheme,
      home: Scaffold(
        backgroundColor: brightness == Brightness.dark
            ? Colors.black
            : const Color(0xFF1A1A1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CheckinResultBanner(state: state),
          ),
        ),
      ),
    );
  }
}

/// 엔트리 그룹 행 목록 — 고정 카드로 골든 렌더.
class _GroupListCard extends StatelessWidget {
  const _GroupListCard({
    required this.groups,
    required this.brightness,
  });
  final List<EntryGroupCheckinStats> groups;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = brightness == Brightness.dark
        ? MinglitTheme.materialThemeDark
        : MinglitTheme.materialTheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.screenEdge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < groups.length; i++)
                Semantics(
                  label:
                      '${groups[i].label}, ${groups[i].checkedIn}명 체크인, '
                      '총 ${groups[i].total}명 중, '
                      '${(groups[i].ratio * 100).toStringAsFixed(0)}퍼센트',
                  child: EntryGroupRow(
                    stats: groups[i],
                    showDivider: i < groups.length - 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ManualCheckinSheet 골든 래퍼 — ProviderScope 포함.
class _ManualSheetGolden extends StatelessWidget {
  const _ManualSheetGolden({
    required this.controller,
    required this.brightness,
  });
  final ManualCheckinController Function() controller;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        manualCheckinControllerProvider(_kEventId).overrideWith(controller),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? MinglitTheme.materialThemeDark
            : MinglitTheme.materialTheme,
        home: const Scaffold(
          body: ManualCheckinSheet(eventId: _kEventId),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scenario definitions
// ---------------------------------------------------------------------------

class QrCheckinScenarios {
  static List<PartnerScreenshotScenario> get all => [
    // 1. 스캔 성공 배너 (light / dark)
    const PartnerScreenshotScenario(
      name: 'qr_checkin_success_banner',
      page: _BannerCard(
        state: CheckinState(
          result: CheckinResult.success,
          userName: '홍길동',
        ),
        brightness: Brightness.light,
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'qr_checkin_success_banner_dark',
      page: _BannerCard(
        state: CheckinState(
          result: CheckinResult.success,
          userName: '홍길동',
        ),
        brightness: Brightness.dark,
      ),
      isComponent: true,
    ),

    // 2. 스캔 오류 배너 (light / dark)
    const PartnerScreenshotScenario(
      name: 'qr_checkin_error_banner',
      page: _BannerCard(
        state: CheckinState(
          result: CheckinResult.invalid,
          message: '유효하지 않은 티켓입니다.',
        ),
        brightness: Brightness.light,
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'qr_checkin_error_banner_dark',
      page: _BannerCard(
        state: CheckinState(
          result: CheckinResult.invalid,
          message: '유효하지 않은 티켓입니다.',
        ),
        brightness: Brightness.dark,
      ),
      isComponent: true,
    ),

    // 3. 엔트리 그룹 확장 (light / dark)
    const PartnerScreenshotScenario(
      name: 'qr_checkin_group',
      page: _GroupListCard(
        groups: [_groupHigh, _groupMid, _groupLow],
        brightness: Brightness.light,
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'qr_checkin_group_dark',
      page: _GroupListCard(
        groups: [_groupHigh, _groupMid, _groupLow],
        brightness: Brightness.dark,
      ),
      isComponent: true,
    ),

    // 4. 수동 체크인 — 참가자 있음 (light / dark)
    PartnerScreenshotScenario(
      name: 'qr_checkin_manual_data',
      page: _ManualSheetGolden(
        controller: () =>
            _FakeManualCheckinController([_participantA, _participantB]),
        brightness: Brightness.light,
      ),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'qr_checkin_manual_data_dark',
      page: _ManualSheetGolden(
        controller: () =>
            _FakeManualCheckinController([_participantA, _participantB]),
        brightness: Brightness.dark,
      ),
      isComponent: true,
    ),

    // 5. 수동 체크인 — 빈 상태 (light / dark)
    PartnerScreenshotScenario(
      name: 'qr_checkin_manual_empty',
      page: _ManualSheetGolden(
        controller: () => _FakeManualCheckinController([]),
        brightness: Brightness.light,
      ),
      isComponent: true,
    ),
    PartnerScreenshotScenario(
      name: 'qr_checkin_manual_empty_dark',
      page: _ManualSheetGolden(
        controller: () => _FakeManualCheckinController([]),
        brightness: Brightness.dark,
      ),
      isComponent: true,
    ),

    // 6. 수동 체크인 — 오프라인/오류 (light / dark)
    const PartnerScreenshotScenario(
      name: 'qr_checkin_manual_offline',
      page: _ManualSheetGolden(
        controller: _ErrorManualCheckinController.new,
        brightness: Brightness.light,
      ),
      isComponent: true,
    ),
    const PartnerScreenshotScenario(
      name: 'qr_checkin_manual_offline_dark',
      page: _ManualSheetGolden(
        controller: _ErrorManualCheckinController.new,
        brightness: Brightness.dark,
      ),
      isComponent: true,
    ),
  ];
}
