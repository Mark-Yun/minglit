import 'package:flutter/material.dart';
import 'package:mds/mds.dart';

/// Generic full-screen confirmation page shown after a successful flow
/// (e.g. event application, payment complete).
class MinglitConfirmationPage extends StatelessWidget {
  const MinglitConfirmationPage({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: MinglitColors.success,
              ),
              const SizedBox(height: MinglitSpacing.medium),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MinglitSpacing.small),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MinglitColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
              if (secondaryLabel != null && onSecondary != null) ...[
                const SizedBox(height: MinglitSpacing.small),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
