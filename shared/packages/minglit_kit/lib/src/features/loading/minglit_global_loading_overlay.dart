import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/loading/global_loading_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

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
  const MinglitGlobalLoadingOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54, // Opacity 0.54 roughly
                child: ModalBarrier(
                  dismissible: false,
                  color:
                      Colors.transparent, // Color handled by container for perf
                ),
              ),
            ),
          if (isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: MinglitColors.primary,
                  ),
                  if (state.onCancel != null) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        state.onCancel!();
                        ref
                            .read(globalLoadingControllerProvider.notifier)
                            .hide();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
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
