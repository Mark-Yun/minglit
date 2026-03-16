import 'dart:async';

import 'package:app_partner/src/features/onboarding/widgets/dot_indicator.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Onboarding welcome page shown to new partners before starting the
/// application wizard. Displays a 4-page swipeable introduction to the
/// Minglit partner service.
class PartnerWelcomePage extends ConsumerStatefulWidget {
  const PartnerWelcomePage({super.key});

  @override
  ConsumerState<PartnerWelcomePage> createState() => _PartnerWelcomePageState();
}

class _PartnerWelcomePageState extends ConsumerState<PartnerWelcomePage> {
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: l10n.welcome_appbar_title,
        showBackButton: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(context.l10n.home_button_logout),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                _WelcomePage(
                  icon: Icons.business_center_outlined,
                  title: l10n.welcome_page1_title,
                  body: l10n.welcome_page1_body,
                ),
                _WelcomePage(
                  icon: Icons.checklist_outlined,
                  title: l10n.welcome_page2_title,
                  body: l10n.welcome_page2_body,
                ),
                _WelcomePage(
                  icon: Icons.celebration_outlined,
                  title: l10n.welcome_page3_title,
                  body: l10n.welcome_page3_body,
                ),
                _WelcomePage(
                  icon: Icons.format_quote_outlined,
                  title: l10n.welcome_page4_title,
                  body: l10n.welcome_page4_body,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.large),
            child: DotIndicator(
              currentIndex: _currentPage,
              totalCount: _totalPages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: ElevatedButton(
            onPressed: () => context.go('/apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MinglitColors.primary,
              foregroundColor: MinglitColors.background,
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.medium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.button),
              ),
            ),
            child: Text(l10n.welcome_cta_button),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(context.l10n.home_button_logout),
            content: const Text(
              '로그아웃 하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.common_button_cancel),
              ),
              TextButton(
                onPressed: () async {
                  // Fix: dialog를 먼저 닫고 signOut — signOut이 GoRouter redirect를
                  // 트리거하면 dialog context가 무효화되어 검은화면+freeze 발생
                  final authRepo = ref.read(authRepositoryProvider);
                  Navigator.of(context).pop();
                  await Future<void>.delayed(Duration.zero);
                  await authRepo.signOut();
                },
                child: Text(context.l10n.home_button_logout),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.xlarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: MinglitSpacing.xlarge),
          Icon(
            icon,
            size: 80,
            color: MinglitColors.primary,
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
