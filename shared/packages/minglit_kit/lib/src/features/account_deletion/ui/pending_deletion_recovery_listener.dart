import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/deletion_status.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/account_deletion/logic/account_deletion_controller.dart';
import 'package:minglit_kit/src/features/auth/logic/auth_controller.dart';
import 'package:minglit_kit/src/utils/error_ui_handler.dart';
import 'package:minglit_kit/src/utils/feedback_ext.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Prompts signed-in users to recover a pending account deletion.
class PendingDeletionRecoveryListener extends ConsumerStatefulWidget {
  /// Creates a [PendingDeletionRecoveryListener].
  const PendingDeletionRecoveryListener({required this.child, super.key});

  /// Descendant app content that stays mounted behind the dialog flow.
  final Widget child;

  @override
  ConsumerState<PendingDeletionRecoveryListener> createState() =>
      _PendingDeletionRecoveryListenerState();
}

class _PendingDeletionRecoveryListenerState
    extends ConsumerState<PendingDeletionRecoveryListener> {
  bool _isHandlingSignIn = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      next.whenData((authState) {
        // Fix #890: only prompt once when a fresh sign-in completes.
        if (authState.event != AuthChangeEvent.signedIn || _isHandlingSignIn) {
          return;
        }

        unawaited(_handlePendingDeletionRecovery());
      });
    });

    return widget.child;
  }

  Future<void> _handlePendingDeletionRecovery() async {
    _isHandlingSignIn = true;

    try {
      final status = await ref
          .read(accountDeletionControllerProvider.notifier)
          .checkStatus();

      if (!mounted || status?.isPending != true) return;

      // Fix #890: signed-in users within the grace period must choose whether
      // to restore the account immediately or sign back out.
      final shouldCancelDeletion = await context.showMinglitConfirm(
        title: '탈퇴 대기 중인 계정입니다',
        message: _buildRecoveryMessage(status!),
        confirmLabel: '취소할게요',
        cancelLabel: '탈퇴 유지',
      );

      if (!mounted) return;

      if (shouldCancelDeletion) {
        await ref
            .read(accountDeletionControllerProvider.notifier)
            .cancelDeletion();
      } else {
        await ref.read(authControllerProvider.notifier).signOut();
      }
    } on Object catch (error, stackTrace) {
      if (mounted) {
        handleMinglitError(context, error, stackTrace);
      }
    } finally {
      _isHandlingSignIn = false;
    }
  }

  String _buildRecoveryMessage(DeletionStatus status) {
    final gracePeriodEnds = status.gracePeriodEnds;
    if (gracePeriodEnds == null) {
      return '7일 유예 기간 중인 계정이에요. 탈퇴를 취소할까요?';
    }

    final now = DateTime.now();
    final remaining = gracePeriodEnds.difference(now);
    final remainingDays = remaining.isNegative
        ? 0
        : (remaining.inHours / 24).ceil();

    return '$remainingDays일 후 계정이 영구 삭제돼요. 탈퇴를 취소할까요?';
  }
}
