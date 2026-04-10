import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_bottom_sheet.dart';

/// Design catalog tab displaying overlay widgets.
class OverlaySection extends StatelessWidget {
  /// Creates an [OverlaySection].
  const OverlaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // AlertDialog
        Text('AlertDialog', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Action'),
                  content: const Text('Are you sure you want to proceed?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show AlertDialog'),
        ),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Item'),
                  content: const Text(
                    'This action cannot be undone. '
                    'Are you sure you want to delete?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // ignore: minglit_no_hardcoded_colors -- catalog demo
                        backgroundColor: MinglitColors.error,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show Destructive Dialog'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitBottomSheet
        Text('MinglitBottomSheet', style: theme.textTheme.titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        Text('With Title', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'showMinglitBottomSheet으로 통일된 바텀시트를 표시합니다.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showMinglitBottomSheet<void>(
                context: context,
                title: '옵션 선택',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '바텀시트 내용입니다. 핸들과 제목이 자동으로 포함됩니다.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show with Title'),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('Without Title', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showMinglitBottomSheet<void>(
                context: context,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '제목 없이 핸들과 콘텐츠만 표시됩니다.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show without Title'),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('No Handle', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              showMinglitBottomSheet<void>(
                context: context,
                title: '핸들 없음',
                showHandle: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '드래그 핸들 없이 제목과 콘텐츠만 표시됩니다.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                  ],
                ),
              ),
            );
          },
          child: const Text('Show without Handle'),
        ),
      ],
    );
  }
}
