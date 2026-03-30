import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/loading/global_loading_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';

/// **Minglit Global Loading Overlay**
///
/// A widget that overlays a loading indicator and blocks user interaction
/// when [globalLoadingControllerProvider] is true.
///
/// **Setup:**
/// Wrap your [MaterialApp.builder] child with this widget.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return MinglitGlobalLoadingOverlay(child: child!);
///   },
/// );
/// ```
class MinglitGlobalLoadingOverlay extends ConsumerWidget {
  /// Creates a global loading overlay wrapper.
  const MinglitGlobalLoadingOverlay({required this.child, super.key});

  /// The app content to wrap with the overlay.
  final Widget child;

  /// Builds the overlay around [child].
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(globalLoadingControllerProvider);
    final isLoading = state.isVisible;

    // Handle Back Button (Android)
    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isLoading && state.onCancel != null) {
          state.onCancel!();
          ref.read(globalLoadingControllerProvider.notifier).hide();
        }
      },
      child: Stack(
        children: [
          child,
          if (isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                child: const ModalBarrier(
                  dismissible: false,
                ),
              ),
            ),
          if (isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MinglitCircularProgressIndicator(
                    color: MinglitColors.primary,
                  ),
                  if (state.onCancel != null) ...[
                    const SizedBox(height: MinglitSpacing.large),
                    TextButton(
                      onPressed: () {
                        state.onCancel!();
                        ref
                            .read(globalLoadingControllerProvider.notifier)
                            .hide();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.surface,
                        backgroundColor: theme.colorScheme.surface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
