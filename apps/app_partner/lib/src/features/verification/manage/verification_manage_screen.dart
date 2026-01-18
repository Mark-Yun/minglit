import 'package:app_partner/src/features/verification/manage/verification_manage_controller.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class VerificationManageScreen extends ConsumerWidget {
  const VerificationManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(verificationManageControllerProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('커스텀 인증 관리'),
          centerTitle: false,
          backgroundColor: theme.colorScheme.surface,
          scrolledUnderElevation: 0,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: '사용 중'),
              Tab(text: '보관됨'),
            ],
          ),
        ),
        body: MinglitAsyncValueWidget(
          value: asyncState,
          data: (state) => TabBarView(
            children: [
              // 1. Active List
              _ActiveList(
                verifications: state.active,
                onArchive: (id) => _confirmArchive(context, ref, id),
              ),
              // 2. Archived List
              _ArchivedList(
                verifications: state.archived,
                onRestore: (id) => _confirmRestore(context, ref, id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    Verification verification,
  ) async {
    final confirmed = await MinglitAlert.showConfirm(
      context: context,
      title: '인증 보관',
      content:
          "'${verification.displayName}' 인증을 보관함으로 이동하시겠습니까?\n\n"
          '더 이상 새로운 파티에 이 인증을 사용할 수 없게 됩니다.',
      confirmText: '보관하기',
      isDestructive: true,
    );

    if (confirmed) {
      await ref
          .read(verificationManageControllerProvider.notifier)
          .archiveVerification(verification.id);
    }
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    Verification verification,
  ) async {
    final confirmed = await MinglitAlert.showConfirm(
      context: context,
      title: '인증 복구',
      content:
          "'${verification.displayName}' 인증을 복구하시겠습니까?\n\n"
          '다시 파티 생성 시 선택할 수 있게 됩니다.',
      confirmText: '복구하기',
    );

    if (confirmed) {
      await ref
          .read(verificationManageControllerProvider.notifier)
          .restoreVerification(verification.id);
    }
  }
}

class _ActiveList extends StatelessWidget {
  const _ActiveList({required this.verifications, required this.onArchive});

  final List<Verification> verifications;
  final void Function(Verification) onArchive;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AddActionCard(
            title: '새로운 인증 만들기',
            subtitle: '우리 가게만의 특별한 입장 조건을 만들어보세요.',
            onTap: () => const CreateVerificationRoute().push<void>(context),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          if (verifications.isEmpty)
            const _EmptyState(message: '생성된 인증이 없습니다.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: verifications.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MinglitSpacing.medium),
              itemBuilder: (context, index) {
                final verification = verifications[index];
                return _VerificationManageCard(
                  verification: verification,
                  actionIcon: Icons.archive_outlined,
                  actionTooltip: '보관하기',
                  onAction: () => onArchive(verification),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ArchivedList extends StatelessWidget {
  const _ArchivedList({required this.verifications, required this.onRestore});

  final List<Verification> verifications;
  final void Function(Verification) onRestore;

  @override
  Widget build(BuildContext context) {
    if (verifications.isEmpty) {
      return const _EmptyState(message: '보관된 인증이 없습니다.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      itemCount: verifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: MinglitSpacing.medium),
      itemBuilder: (context, index) {
        final verification = verifications[index];
        return _VerificationManageCard(
          verification: verification,
          actionIcon: Icons.restore_from_trash,
          actionTooltip: '복구하기',
          onAction: () => onRestore(verification),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.xlarge),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: MinglitIconSize.xlarge * 1.5,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationManageCard extends StatelessWidget {
  const _VerificationManageCard({
    required this.verification,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  });

  final Verification verification;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return VerificationCard(
      verification: verification,
      trailing: IconButton(
        icon: Icon(actionIcon),
        color: colorScheme.onSurfaceVariant,
        tooltip: actionTooltip,
        onPressed: onAction,
      ),
    );
  }
}
