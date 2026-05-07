import 'dart:async';

// Fix #2145: import from logic/ — eliminates cross-feature application → party/event dependency
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_application_detail_page.g.dart';

@riverpod
Future<EventApplication?> eventApplicationDetail(
  Ref ref,
  String applicationId,
) async {
  return ref.read(eventRepositoryProvider).getApplicationById(applicationId);
}

class EventApplicationDetailPage extends ConsumerStatefulWidget {
  const EventApplicationDetailPage({
    required this.applicationId,
    super.key,
  });

  final String applicationId;

  @override
  ConsumerState<EventApplicationDetailPage> createState() =>
      _EventApplicationDetailPageState();
}

class _EventApplicationDetailPageState
    extends ConsumerState<EventApplicationDetailPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(eventApplicationReviewControllerProvider, (_, next) {
      if (next is AsyncData) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('처리가 완료되었습니다.')),
          );
          Navigator.of(context).pop();
        }
      }
      if (next is AsyncError) {
        if (mounted) handleMinglitError(context, next.error, next.stackTrace);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final applicationAsync = ref.watch(
      eventApplicationDetailProvider(widget.applicationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('신청 상세')),
      body: MinglitAsyncValueWidget(
        value: applicationAsync,
        data: (application) {
          if (application == null) {
            return const Center(child: Text('신청 정보를 찾을 수 없습니다.'));
          }
          return _ApplicationDetailBody(
            application: application,
            onApprove: () => _review(application.id, 'approved'),
            onReject: (reason) =>
                _review(application.id, 'rejected', reason: reason),
          );
        },
      ),
    );
  }

  Future<void> _review(
    String applicationId,
    String status, {
    String? reason,
  }) async {
    await ref
        .read(eventApplicationReviewControllerProvider.notifier)
        .reviewApplication(
          applicationId: applicationId,
          status: status,
          reason: reason,
        );
  }
}

class _ApplicationDetailBody extends StatelessWidget {
  const _ApplicationDetailBody({
    required this.application,
    required this.onApprove,
    required this.onReject,
  });

  final EventApplication application;
  final VoidCallback onApprove;
  final void Function(String? reason) onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = application.user;
    // Fix #2250: use username (닉네임) not name (실명) — PM #1141 & PIPA §17.
    // name is actual name; partners are allowed to see nickname + age group only.
    final hasUsername = user?.username.isNotEmpty == true;
    final displayName = hasUsername ? user!.username : '—';
    // Fix #2250: avatar uses first letter of valid username only — '—' fallback must
    // not bleed into avatar so findsOneWidget('—') holds in the empty-username case.
    final avatarChar = hasUsername ? user!.username[0] : '?';
    // Fix #2250: birth_date selected from user_profiles; derive year for age display.
    // birthYear fallback covers unit-test fixtures that supply it directly.
    final birthYear = user?.birthDate?.year ?? user?.birthYear;
    final age = birthYear != null ? DateTime.now().year - birthYear : null;
    // Fix #2250: gender excluded per PM #1141 ("성별은 제외").

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: MinglitOpacity.highlight,
                    ),
                    child: Text(
                      avatarChar,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        // Fix #2250: age (연령대) only — no gender per PM #1141
                        if (age != null)
                          Text(
                            '$age세',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: application.status),
                ],
              ),
            ),
          ),

          const SizedBox(height: MinglitSpacing.medium),

          // Application info
          Text(
            '신청 정보',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  title: const Text('신청일'),
                  trailing: Text(
                    _formatDate(application.createdAt),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (application.paymentAmount != null &&
                    application.paymentAmount! > 0)
                  ListTile(
                    dense: true,
                    title: const Text('결제금액'),
                    trailing: Text(
                      '${application.paymentAmount!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                if (application.rejectionReason != null)
                  ListTile(
                    dense: true,
                    title: const Text('거절 사유'),
                    subtitle: Text(application.rejectionReason!),
                  ),
              ],
            ),
          ),

          // Pending: approve/reject actions
          if (application.status == 'pending_review') ...[
            const SizedBox(height: MinglitSpacing.large),
            Text(
              '심사',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.close, color: MinglitColors.error),
                    label: const Text(
                      '거절',
                      style: TextStyle(color: MinglitColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MinglitColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거절 사유'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '거절 사유를 입력해주세요 (선택)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('거절'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null) onReject(reason.isEmpty ? null : reason);
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = switch (status) {
      'pending_review' => (MinglitColors.warning, '심사 중'),
      'approved' => (MinglitColors.success, '승인됨'),
      'rejected' => (theme.colorScheme.error, '거절됨'),
      'paid' => (theme.colorScheme.primary, '결제완료'),
      _ => (theme.colorScheme.outline, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: MinglitOpacity.highlight),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(
          color: color.withValues(alpha: MinglitOpacity.strong),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
