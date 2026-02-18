import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';

/// **Minglit Async Value Widget**
///
/// A standardized wrapper for Riverpod's [AsyncValue].
/// Automatically handles `loading` and `error` states with Minglit UI tokens.
class MinglitAsyncValueWidget<T> extends StatelessWidget {
  /// Creates a wrapper that handles [AsyncValue] states.
  const MinglitAsyncValueWidget({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.showErrorDetails = false,
    super.key,
  });

  /// The [AsyncValue] to handle.
  final AsyncValue<T> value;

  /// The widget to display when data is available.
  final Widget Function(T) data;

  /// Optional custom loading widget.
  /// Defaults to [MinglitCircularProgressIndicator].
  final Widget Function()? loading;

  /// Optional custom error widget.
  final Widget Function(Object, StackTrace)? error;

  /// Whether to show full error details in the default error view.
  final bool showErrorDetails;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: loading ?? () => const MinglitCircularProgressIndicator(),
      error:
          error ??
          (err, stack) => _DefaultErrorView(
            error: err,
            stackTrace: stack,
            showDetails: showErrorDetails,
          ),
    );
  }
}

class _DefaultErrorView extends StatelessWidget {
  const _DefaultErrorView({
    required this.error,
    required this.stackTrace,
    this.showDetails = false,
  });

  final Object error;
  final StackTrace stackTrace;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: MinglitIconSize.xlarge,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '오류가 발생했습니다.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: MinglitSpacing.small),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
