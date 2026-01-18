import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A branded splash screen shown during app initialization.
class MinglitSplashScreen extends StatelessWidget {
  /// Creates a [MinglitSplashScreen].
  const MinglitSplashScreen({
    required this.appName,
    super.key,
    this.isPartner = false,
  });

  /// The name of the specific application.
  final String appName;

  /// Whether this is for the Partner app.
  final bool isPartner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MinglitColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MinglitImage(
              path:
                  'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
              height: 64,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              appName.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MinglitColors.textSecondary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: MinglitSpacing.xlarge * 1.5),
            const MinglitCircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
