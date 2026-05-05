part of 'event_application_wizard_page.dart';

class _VerificationStep extends ConsumerWidget {
  const _VerificationStep({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(eventApplicationControllerProvider(event));
    final ticket = state.selectedTicket;
    if (ticket == null) return const Text('티켓을 먼저 선택해주세요.');
    final entries = state.partnerVerifications;
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: MinglitSpacing.xlarge + MinglitSpacing.small,
          ),
          child: Text(
            '이 티켓은 추가 인증이 필요하지 않습니다.\n바로 결제로 진행해주세요.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '파트너 추가 인증',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          '파트너가 요청한 인증 항목을 입력해주세요. 이미 승인된 항목은 자동으로 반영됩니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
            child: _VerificationEntryCard(event: event, entry: entry),
          ),
        ),
      ],
    );
  }
}

class _VerificationEntryCard extends ConsumerWidget {
  const _VerificationEntryCard({required this.event, required this.entry});

  final Event event;
  final PartnerVerifEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentData = ref
        .watch(eventApplicationControllerProvider(event))
        .verificationData[entry.verification.id];
    final resolvedData = currentData ?? entry.prefill;

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.verification.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _VerificationStatusBadge(entry: entry),
            ],
          ),
          if (entry.verification.description != null) ...[
            const SizedBox(height: MinglitSpacing.small),
            Text(
              entry.verification.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (entry.rejectionReason != null) ...[
            const SizedBox(height: MinglitSpacing.small),
            Text(
              entry.rejectionReason!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (!entry.isApproved) ...[
            const SizedBox(height: MinglitSpacing.medium),
            ...entry.verification.formSchema.map(
              (field) => _VerificationFormFieldView(
                event: event,
                verificationId: entry.verification.id,
                field: field,
                initialValue: resolvedData[field.key],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationStatusBadge extends StatelessWidget {
  const _VerificationStatusBadge({required this.entry});

  final PartnerVerifEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch ((entry.isApproved, entry.isRejected)) {
      (true, _) => ('승인 완료', MinglitColors.success),
      (false, true) => ('재제출 필요', theme.colorScheme.error),
      _ => ('입력 필요', theme.colorScheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
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

class _VerificationFormFieldView extends ConsumerWidget {
  const _VerificationFormFieldView({
    required this.event,
    required this.verificationId,
    required this.field,
    this.initialValue,
  });

  final Event event;
  final String verificationId;
  final VerificationFormField field;
  final dynamic initialValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(
      eventApplicationControllerProvider(event).notifier,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.required ? '${field.label} *' : field.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          if (field.type == 'file')
            Builder(
              builder: (context) {
                final userId = ref.read(currentUserProvider)?.id;
                if (userId == null) {
                  return const Text('로그인이 필요합니다.');
                }
                return MinglitFilePicker(
                  label: field.label,
                  hint: field.placeholder ?? '증빙 서류를 업로드해주세요',
                  fileType: FileType.any,
                  autoUpload: true,
                  uploadBucket: 'verification-proofs',
                  uploadPathPrefix: '$userId/applications/${event.id}',
                  onUploadComplete: (urls) {
                    controller.updateVerificationData(
                      verificationId,
                      field.key,
                      urls.isEmpty ? null : urls.first,
                    );
                  },
                  onFilesSelected: (_) {},
                );
              },
            )
          else
            TextFormField(
              initialValue: initialValue?.toString(),
              decoration: InputDecoration(
                hintText: field.placeholder ?? '${field.label}을(를) 입력하세요',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.updateVerificationData(
                  verificationId,
                  field.key,
                  value,
                );
              },
            ),
        ],
      ),
    );
  }
}
