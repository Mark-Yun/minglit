import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step1BasicInfo extends ConsumerWidget {
  const Step1BasicInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        children: [
          Text('Step 1: Title, Image, Description'),
        ],
      ),
    );
  }
}
