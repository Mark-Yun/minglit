
import 'package:app_user/src/features/event/detail/html_stub.dart' if (dart.library.html) 'dart:html' as html show window;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detects if the current platform is a mobile web browser.
bool get _isMobileWeb {
  if (!kIsWeb) return false;
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('mobile') ||
      ua.contains('android') ||
      ua.contains('iphone');
}

/// A bottom banner displayed on mobile web to nudge users to the Minglit app.
class OpenInAppBanner extends ConsumerWidget {
  /// Callback when the user dismisses the banner.
  const OpenInAppBanner({
    required this.onDismiss,
    super.key,
  });

  /// Called when the user taps the close button.
  final VoidCallback onDismiss;

  Future<void> _launchApp(WidgetRef ref) async {
    final config = ref.read(minglitUrlConfigProvider);
    final url = Uri.parse(config.landingHome);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isMobileWeb) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: MinglitRadius.small,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.small,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '앱에서 더 편하게 보기',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              FilledButton(
                onPressed: () => _launchApp(ref),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('앱에서 보기'),
              ),
              const SizedBox(width: MinglitSpacing.xsmall),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                iconSize: MinglitIconSize.small,
                color: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                tooltip: '닫기',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
