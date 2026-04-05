import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_alert.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_dialog.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_empty_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_error_state.dart';

/// Design catalog tab displaying feedback widgets.
class FeedbackSection extends StatelessWidget {
  /// Creates a [FeedbackSection].
  const FeedbackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // MinglitEmptyState
        Text('MinglitEmptyState', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: MinglitEmptyState(
            title: '저장된 항목이 없습니다',
            subtitle: '새로운 항목을 추가해보세요',
            actionLabel: '새로 만들기',
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitErrorState
        Text('MinglitErrorState', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: MinglitErrorState(
            title: '데이터를 불러올 수 없습니다',
            subtitle: '네트워크 연결을 확인해주세요',
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitAlert
        Text('MinglitAlert', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Tap buttons to preview alerts.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        ElevatedButton(
          onPressed: () {
            unawaited(
              MinglitAlert.show(
                context: context,
                title: '알림',
                content: '작업이 완료되었습니다.',
              ),
            );
          },
          child: const Text('Show Info Alert'),
        ),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              MinglitAlert.showConfirm(
                context: context,
                title: '삭제하시겠습니까?',
                content: '이 작업은 되돌릴 수 없습니다.',
                isDestructive: true,
              ),
            );
          },
          child: const Text('Show Destructive Confirm'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitDialog
        Text('MinglitDialog', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        ElevatedButton(
          onPressed: () {
            unawaited(
              MinglitDialog.show(
                context: context,
                title: '커스텀 다이얼로그',
                content: const Text('MinglitDialog는 제목 + 콘텐츠 + 액션을 조합합니다.'),
              ),
            );
          },
          child: const Text('Show MinglitDialog'),
        ),
      ],
    );
  }
}
