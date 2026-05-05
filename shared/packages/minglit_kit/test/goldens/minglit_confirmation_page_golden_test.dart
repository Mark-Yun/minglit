@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap({
  required Brightness brightness,
  required MinglitConfirmationTone tone,
  required IconData icon,
  required String title,
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark
        ? MinglitTheme.materialThemeDark
        : MinglitTheme.materialTheme,
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MinglitConfirmationPage(
        title: title,
        description: '서로 좋아요가 맞으면 결과 화면에서 알려드릴게요.',
        icon: icon,
        tone: tone,
        ctaLabel: '닫기',
        onPressed: () {},
      ),
    ),
  );
}

void main() {
  goldenTest(
    'minglit confirmation page tones',
    fileName: 'minglit_confirmation_page_tones',
    builder: () => GoldenTestGroup(
      columnWidthBuilder: (_) => const FixedColumnWidth(400),
      children: [
        GoldenTestScenario(
          name: 'success light',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.light,
              tone: MinglitConfirmationTone.success,
              icon: Icons.check_rounded,
              title: '좋아요를 보냈어요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'primary light',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.light,
              tone: MinglitConfirmationTone.primary,
              icon: Icons.favorite_border_rounded,
              title: '매칭 준비가 끝났어요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'info light',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.light,
              tone: MinglitConfirmationTone.info,
              icon: Icons.info_outline_rounded,
              title: '결과를 확인해 주세요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'warning light',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.light,
              tone: MinglitConfirmationTone.warning,
              icon: Icons.warning_amber_rounded,
              title: '선택 수를 다시 확인해 주세요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'success dark',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.dark,
              tone: MinglitConfirmationTone.success,
              icon: Icons.check_rounded,
              title: '좋아요를 보냈어요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'primary dark',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.dark,
              tone: MinglitConfirmationTone.primary,
              icon: Icons.favorite_border_rounded,
              title: '매칭 준비가 끝났어요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'info dark',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.dark,
              tone: MinglitConfirmationTone.info,
              icon: Icons.info_outline_rounded,
              title: '결과를 확인해 주세요',
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'warning dark',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _wrap(
              brightness: Brightness.dark,
              tone: MinglitConfirmationTone.warning,
              icon: Icons.warning_amber_rounded,
              title: '선택 수를 다시 확인해 주세요',
            ),
          ),
        ),
      ],
    ),
  );
}
