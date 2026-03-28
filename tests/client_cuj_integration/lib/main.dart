import 'package:flutter/material.dart';

void main() {
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
            'E2E Automation Tester\n'
            'Run via: flutter test integration_test/',
          ),
        ),
      ),
    );
  }
}
