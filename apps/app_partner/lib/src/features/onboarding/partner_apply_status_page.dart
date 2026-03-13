import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

import 'package:minglit_kit/minglit_kit.dart';

/// Application status page shown when user has a pending
/// or needs_correction application.
class PartnerApplyStatusPage extends ConsumerWidget {
  const PartnerApplyStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final onboardingAsync = ref.watch(onboardingStateProvider);
    final applicationAsync = ref.watch(
      FutureProvider((ref) {
        final repo = ref.read(partnerRepositoryProvider);
        return repo.getMyApplication();
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.partnerApplication_status_title),
        automaticallyImplyLeading: false,
      ),
      body: MinglitAsyncValueWidget<OnboardingState>(
        value: onboardingAsync,
        data: (onboardingState) {
          return MinglitAsyncValueWidget<PartnerApplication?>(
            value: applicationAsync,
            data: (application) => _buildContent(
              context,
              ref,
              onboardingState,
              application,
              l10n,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    OnboardingState onboardingState,
    PartnerApplication? application,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MinglitSpacing.xlarge),
          _buildStatusIcon(onboardingState),
          const SizedBox(height: MinglitSpacing.large),
          _buildStatusMessage(context, onboardingState, application, l10n),
          const SizedBox(height: MinglitSpacing.xlarge),
          if (onboardingState == OnboardingState.needsCorrection) ...[
            _buildEditButton(context, l10n),
            const SizedBox(height: MinglitSpacing.medium),
          ],
          _buildLogoutButton(context, ref, l10n),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(OnboardingState state) {
    final isNeedsCorrection = state == OnboardingState.needsCorrection;
    return Icon(
      isNeedsCorrection
          ? Icons.warning_amber_rounded
          : Icons.hourglass_top_rounded,
      size: 80,
      color: isNeedsCorrection ? MinglitColors.warning : MinglitColors.primary,
    );
  }

  Widget _buildStatusMessage(
    BuildContext context,
    OnboardingState onboardingState,
    PartnerApplication? application,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    if (onboardingState == OnboardingState.needsCorrection) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partnerApplication_status_needsCorrection,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (application?.adminComment != null) ...[
            const SizedBox(height: MinglitSpacing.medium),
            Container(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              decoration: BoxDecoration(
                color: MinglitColors.surface,
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.partnerApplication_status_adminComment,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: MinglitColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  Text(
                    application!.adminComment!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Pending state
    return Text(
      l10n.partnerApplication_status_pending,
      style: theme.textTheme.bodyLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEditButton(BuildContext context, AppLocalizations l10n) {
    return FilledButton(
      onPressed: () => const PartnerApplyRoute().go(context),
      child: Text(l10n.partnerApplication_button_editApplication),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signOut();
      },
      child: Text(l10n.home_button_logout),
    );
  }
}
