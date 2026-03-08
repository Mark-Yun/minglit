import 'package:flutter/material.dart';
import 'package:minglit_kit/src/ui/feedback/feedback_components.dart';

/// **Minglit Feedback Extensions**
///
/// Provides convenient methods to show standardized snackbars and dialogs.
extension MinglitFeedbackX on BuildContext {
  /// Shows a success snackbar.
  void showMinglitSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      MinglitFeedbackUI.buildSnackBar(
        context: this,
        message: message,
        type: MinglitFeedbackType.success,
      ),
    );
  }

  /// Shows an info snackbar.
  void showMinglitInfo(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      MinglitFeedbackUI.buildSnackBar(
        context: this,
        message: message,
        type: MinglitFeedbackType.info,
      ),
    );
  }

  /// Shows a warning snackbar.
  void showMinglitWarning(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      MinglitFeedbackUI.buildSnackBar(
        context: this,
        message: message,
        type: MinglitFeedbackType.warning,
      ),
    );
  }

  /// Shows an alert dialog.
  Future<void> showMinglitAlert({
    required String title,
    required String message,
    String? confirmLabel,
  }) async {
    await showDialog<void>(
      context: this,
      builder: (context) => MinglitFeedbackUI.buildDialog(
        context: context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );
  }

  /// Shows a confirmation dialog.
  /// Returns true if confirmed, false if cancelled.
  Future<bool> showMinglitConfirm({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => MinglitFeedbackUI.buildDialog(
        context: context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isConfirm: true,
      ),
    );
    return result ?? false;
  }
}
