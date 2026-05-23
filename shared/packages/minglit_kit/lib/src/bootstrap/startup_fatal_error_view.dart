import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mds/mds.dart';

/// Default fatal startup error screen.
class StartupFatalErrorView extends StatelessWidget {
  /// Creates a fatal startup error screen.
  const StartupFatalErrorView({
    required this.error,
    super.key,
    this.onRetry,
    this.showDetails = !kReleaseMode,
  });

  /// Fatal startup error.
  final Object error;

  /// Called when the user taps retry.
  final VoidCallback? onRetry;

  /// Whether to show raw error details.
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MinglitErrorState(
          title: '앱을 시작할 수 없습니다',
          subtitle: showDetails ? '$error' : '잠시 후 다시 시도해 주세요.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}
