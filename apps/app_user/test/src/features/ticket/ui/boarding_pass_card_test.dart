import 'dart:async';

import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:app_user/src/features/ticket/ui/widgets/boarding_pass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Widget tests for BoardingPassCard — Layer 3 per test-plan.md

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 4, 15, 12);

TicketToken _makeToken({String ticketId = 'ticket-abc123'}) {
  return TicketToken(
    ticketId: ticketId,
    eventId: 'event-1',
    userId: 'user-1',
    signature: 'signed-token',
    expiresAt: _now.add(const Duration(days: 1)),
  );
}

TicketEventMeta _makeMeta({
  String title = '금요일 밤 와인 테이스팅',
  DateTime? dateTime,
  String? venue = '강남 라운지바',
  String? ticketName = '일반 입장권',
}) {
  return TicketEventMeta(
    eventTitle: title,
    eventDateTime: dateTime ?? _now,
    eventVenue: venue,
    ticketName: ticketName,
  );
}

/// Host widget that owns the [AnimationController] and passes it to
/// [BoardingPassCard]. This avoids creating a vsync outside the widget tree.
class _Host extends StatefulWidget {
  const _Host({required this.token, this.eventMeta});

  final TicketToken token;
  final TicketEventMeta? eventMeta;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BoardingPassCard(
      token: widget.token,
      scanningAnimation: _controller,
      eventMeta: widget.eventMeta,
    );
  }
}

Widget _wrap({required TicketToken token, TicketEventMeta? eventMeta}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: SingleChildScrollView(
        child: _Host(token: token, eventMeta: eventMeta),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('BoardingPassCard', () {
    // -----------------------------------------------------------------------
    // Header rendering
    // -----------------------------------------------------------------------

    testWidgets('헤더 스트립: "BOARDING PASS" + "입장권" 텍스트 존재', (tester) async {
      await tester.pumpWidget(
        _wrap(token: _makeToken(), eventMeta: _makeMeta()),
      );
      await tester.pump();

      expect(find.text('BOARDING PASS'), findsOneWidget);
      expect(find.text('입장권'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Event info section
    // -----------------------------------------------------------------------

    testWidgets('이벤트 정보 섹션: DATE/VENUE 라벨 + 이벤트명 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(token: _makeToken(), eventMeta: _makeMeta()),
      );
      await tester.pump();

      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('VENUE'), findsOneWidget);
      expect(find.text('금요일 밤 와인 테이스팅'), findsOneWidget);
      expect(find.textContaining('강남 라운지바'), findsOneWidget);
      expect(find.textContaining('TICKET · 일반 입장권'), findsOneWidget);
    });

    testWidgets('이벤트 메타 null → placeholder "—" 표시 (크래시 없음)', (tester) async {
      await tester.pumpWidget(_wrap(token: _makeToken()));
      await tester.pump();

      // Must not throw; header still renders
      expect(find.text('BOARDING PASS'), findsOneWidget);
      // Fix #1532: null-meta graceful degradation — all info fields show "—"
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('긴 이벤트명 (50자+) — 크래시 없고 말줄임 적용', (tester) async {
      final longTitle = 'A' * 55;
      await tester.pumpWidget(
        _wrap(
          token: _makeToken(),
          eventMeta: _makeMeta(title: longTitle),
        ),
      );
      await tester.pump();

      expect(find.byType(BoardingPassCard), findsOneWidget);
    });

    testWidgets('긴 장소명 — 크래시 없고 말줄임 적용', (tester) async {
      await tester.pumpWidget(
        _wrap(
          token: _makeToken(),
          eventMeta: _makeMeta(venue: 'B' * 40),
        ),
      );
      await tester.pump();

      expect(find.byType(BoardingPassCard), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Status badge — uses _now as event DateTime (same day → boarding)
    // -----------------------------------------------------------------------

    testWidgets('BOARDING 상태: "BOARDING" 텍스트 (오늘 이벤트)', (tester) async {
      // Use midday (12:00) to avoid midnight boundary flakiness.
      // boardingPassStatus uses DateTime.now() internally, so both sides
      // must agree on "today" — a fixed midday timestamp is safe.
      final today = DateTime.now();
      final todayMeta = _makeMeta(
        dateTime: DateTime(today.year, today.month, today.day, 12),
      );

      await tester.pumpWidget(
        _wrap(token: _makeToken(), eventMeta: todayMeta),
      );
      await tester.pump();

      expect(find.text('BOARDING'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });

    testWidgets('CONFIRMED 상태: "CONFIRMED" 텍스트 (미래 이벤트)', (tester) async {
      final futureMeta = _makeMeta(
        dateTime: DateTime.now().add(const Duration(days: 7)),
      );

      await tester.pumpWidget(
        _wrap(token: _makeToken(), eventMeta: futureMeta),
      );
      await tester.pump();

      expect(find.text('CONFIRMED'), findsOneWidget);
    });

    testWidgets(
      'USED 상태: "USED" 텍스트 + 카드 opacity 0.55 (지난 이벤트)',
      (tester) async {
        final pastMeta = _makeMeta(
          dateTime: DateTime.now().subtract(const Duration(days: 2)),
        );

        await tester.pumpWidget(
          _wrap(token: _makeToken(), eventMeta: pastMeta),
        );
        await tester.pump();

        expect(find.text('USED'), findsOneWidget);

        // Verify Opacity widget wrapping the card has 0.55
        final opacityWidget = tester.widget<Opacity>(
          find.ancestor(
            of: find.byType(ClipRRect),
            matching: find.byType(Opacity),
          ),
        );
        expect(opacityWidget.opacity, closeTo(MinglitOpacity.overlay, 0.01));
      },
    );

    // -----------------------------------------------------------------------
    // QR stub
    // -----------------------------------------------------------------------

    testWidgets(
      'QR 코드: Semantics label "이벤트 입장 QR 코드" 존재 (접근성)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(token: _makeToken(), eventMeta: _makeMeta()),
        );
        await tester.pump();

        // Use widget predicate instead of semantics tree traversal —
        // more reliable in headless test environments.
        expect(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == '이벤트 입장 QR 코드',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('TICKET NO. 라벨 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(token: _makeToken(), eventMeta: _makeMeta()),
      );
      await tester.pump();

      expect(find.text('TICKET NO.'), findsOneWidget);
    });

    testWidgets('USED 상태: 스캐닝 라인 없음 ("USED" 상태 계약 확인)', (tester) async {
      final pastMeta = _makeMeta(
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
      );

      await tester.pumpWidget(
        _wrap(token: _makeToken(), eventMeta: pastMeta),
      );
      await tester.pump();

      expect(find.text('USED'), findsOneWidget);
      // Scanning line widget must be absent for USED status
      expect(find.byKey(const ValueKey('scanning-line')), findsNothing);
    });

    // -----------------------------------------------------------------------
    // Instruction text not in card
    // -----------------------------------------------------------------------

    testWidgets(
      '카드 자체에 안내 문구("입장 시 파트너에게") 없음 — TicketQRScreen 책임',
      (tester) async {
        await tester.pumpWidget(
          _wrap(token: _makeToken(), eventMeta: _makeMeta()),
        );
        await tester.pump();

        expect(
          find.text('입장 시 파트너에게 이 화면을 보여주세요'),
          findsNothing,
        );
      },
    );

    // Fix #1931 regression guard: _NotchCircle must not use hardcoded
    // MinglitColors.surface in dark mode (causes bright circles on dark page).
    testWidgets(
      'dark mode: notch circles use scaffoldBackgroundColor, not hardcoded surface (Fix #1931)',
      (tester) async {
        final darkTheme = ThemeData.dark(useMaterial3: true);
        await tester.pumpWidget(
          MaterialApp(
            theme: darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: _Host(token: _makeToken(), eventMeta: _makeMeta()),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(BoardingPassCard), findsOneWidget);

        // MinglitColors.surface = 0xFFF9FAFB (light-mode only).
        // In dark mode, notch circles must match scaffoldBackgroundColor.
        const lightSurface = Color(0xFFF9FAFB);
        final circleContainers = tester
            .widgetList<Container>(
              find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).shape == BoxShape.circle,
              ),
            )
            .toList();

        expect(
          circleContainers,
          isNotEmpty,
          reason: 'Expected notch circle Containers in the widget tree',
        );
        for (final c in circleContainers) {
          final color = (c.decoration! as BoxDecoration).color;
          expect(
            color,
            isNot(lightSurface),
            reason:
                '_NotchCircle must not use MinglitColors.surface in dark mode',
          );
        }

        // Divider in _EventInfoSection must also use theme-aware color, not
        // MinglitColors.surface. outlineVariant in dark theme != lightSurface.
        final dividers = tester
            .widgetList<Divider>(find.byType(Divider))
            .toList();
        expect(dividers, isNotEmpty, reason: 'Expected Divider in event info');
        for (final d in dividers) {
          expect(
            d.color,
            isNot(lightSurface),
            reason: 'Divider must not use MinglitColors.surface in dark mode',
          );
        }
      },
    );
  });
}
