import 'package:flutter/material.dart';

void main() {
  // Fix #373: Android 플랫폼 디렉토리 추가로 에뮬레이터 디바이스 인식 문제 해결
  runApp(const E2eAutomationTesterApp());
}

class E2eAutomationTesterApp extends StatelessWidget {
  const E2eAutomationTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Partner E2E Automation Tester\n'
            'Run via: flutter test integration_test/',
          ),
        ),
      ),
    );
  }
}
