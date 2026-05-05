// Fix #2198: MinglitDDayChip 골든 테스트 추가 (3-tier + dark + custom label)
@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: brightness == Brightness.dark
        ? MinglitTheme.materialThemeDark
        : MinglitTheme.materialTheme,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  goldenTest(
    'today tier light',
    fileName: 'dday_chip_today',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(200),
      children: [
        GoldenTestScenario(
          name: 'today tier',
          child: SizedBox(
            width: 200,
            height: 80,
            child: _wrap(const MinglitDDayChip(daysUntil: 0)),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'soon tier light',
    fileName: 'dday_chip_soon',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(200),
      children: [
        GoldenTestScenario(
          name: 'soon tier',
          child: SizedBox(
            width: 200,
            height: 80,
            child: _wrap(const MinglitDDayChip(daysUntil: 3)),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'later tier light',
    fileName: 'dday_chip_later',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(200),
      children: [
        GoldenTestScenario(
          name: 'later tier',
          child: SizedBox(
            width: 200,
            height: 80,
            child: _wrap(const MinglitDDayChip(daysUntil: 12)),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'dark theme',
    fileName: 'dday_chip_dark',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(200),
      children: [
        GoldenTestScenario(
          name: 'dark theme',
          child: SizedBox(
            width: 200,
            height: 80,
            child: _wrap(
              const MinglitDDayChip(daysUntil: 3),
              brightness: Brightness.dark,
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'custom label override',
    fileName: 'dday_chip_custom_label',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(200),
      children: [
        GoldenTestScenario(
          name: 'custom label',
          child: SizedBox(
            width: 200,
            height: 80,
            child: _wrap(
              const MinglitDDayChip(daysUntil: 3, label: '마감 임박'),
            ),
          ),
        ),
      ],
    ),
  );
}
