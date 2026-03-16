import 'package:flutter/material.dart';

class SettlementDetailPage extends StatelessWidget {
  const SettlementDetailPage({required this.itemId, super.key});
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정산 상세')),
      body: Center(child: Text('Settlement Detail: $itemId')),
    );
  }
}
