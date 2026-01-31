import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '더보기'),
      body: const Center(
        child: Text('설정 및 프로필 관리 화면 (준비 중)'),
      ),
    );
  }
}
