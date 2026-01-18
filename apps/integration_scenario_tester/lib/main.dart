import 'package:flutter/material.dart';

void main() {
  runApp(const IntegrationTesterApp());
}

class IntegrationTesterApp extends StatelessWidget {
  const IntegrationTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Minglit Integration Scenario Tester\nRun tests via "flutter test integration_test"',
          ),
        ),
      ),
    );
  }
}
