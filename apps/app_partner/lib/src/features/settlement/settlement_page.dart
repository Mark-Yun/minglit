import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class SettlementPage extends StatelessWidget {
  const SettlementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '정산 관리'),
      body: const Center(
        child: Text('정산 내역 및 관리 화면 (준비 중)'),
      ),
    );
  }
}
