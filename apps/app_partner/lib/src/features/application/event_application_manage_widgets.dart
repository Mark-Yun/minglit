part of 'event_application_manage_page.dart';

/// Dialog for entering a rejection reason.
/// Manages the TextEditingController internally so Flutter disposes it
/// after the close animation completes (not when showDialog resolves).
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('신청 거절'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: '거절 사유를 입력하세요'),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('거절'),
        ),
      ],
    );
  }
}

class _EventGroupSection extends StatelessWidget {
  const _EventGroupSection({
    required this.event,
    required this.applications,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  final Event event;
  final List<EventApplication> applications;
  final bool showActions;
  final void Function(String appId) onApprove;
  final void Function(String appId) onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('M/d (E)', 'ko');
    final timeFmt = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.sm,
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: MinglitOpacity.muted,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Fix #1742: event.title은 nullable — party.title로 폴백
                      '${event.party?.title ?? event.title ?? ''} · ${dateFmt.format(event.startTime)} ${timeFmt.format(event.startTime)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${applications.length}건 · ${event.currentParticipants}/${event.maxParticipants}명',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Application items
        ...applications.map(
          (app) => _ApplicationItem(
            application: app,
            showActions: showActions,
            onApprove: () => onApprove(app.id),
            onReject: () => onReject(app.id),
          ),
        ),
      ],
    );
  }
}

class _ApplicationItem extends StatelessWidget {
  const _ApplicationItem({
    required this.application,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  final EventApplication application;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = application.user;
    final name = user?.name ?? '이름 없음';
    final gender = user?.gender;
    final birthYear = user?.birthYear;
    final age = birthYear != null ? DateTime.now().year - birthYear : null;
    final timeAgo = _formatTimeAgo(application.createdAt);

    final genderText = switch (gender) {
      'male' => '남',
      'female' => '여',
      _ => null,
    };

    final subtitle = [
      if (age != null) '$age세',
      ?genderText,
      timeAgo,
    ].join(' · ');

    // Fix #1860: 승인됨/거절됨 탭 항목 클릭 시 상세 화면으로 이동 (regression from refactor #1914)
    return InkWell(
      onTap: showActions
          ? null
          : () => EventApplicationDetailRoute(
              applicationId: application.id,
            ).push<void>(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: MinglitOpacity.muted),
            ),
          ),
        ),
        child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(
              alpha: MinglitOpacity.highlight,
            ),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: MinglitSpacing.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          // Actions or status
          if (showActions) ...[
            IconButton(
              icon: const Icon(
                Icons.close,
                color: MinglitColors.error,
                size: MinglitIconSize.small,
              ),
              onPressed: onReject,
              tooltip: '거절',
              style: IconButton.styleFrom(
                shape: CircleBorder(
                  side: BorderSide(color: theme.dividerColor),
                ),
                minimumSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            IconButton(
              icon: Icon(
                Icons.check,
                color: theme.colorScheme.onPrimary,
                size: MinglitIconSize.small,
              ),
              onPressed: onApprove,
              tooltip: '승인',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(36, 36),
              ),
            ),
          ] else
            _StatusBadge(status: application.status),
        ],
      ),
    ),
    );
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'approved' || 'paid' => ('승인', MinglitColors.success),
      'rejected' => ('거절', MinglitColors.error),
      _ => ('대기', theme.colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: MinglitOpacity.highlight),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
