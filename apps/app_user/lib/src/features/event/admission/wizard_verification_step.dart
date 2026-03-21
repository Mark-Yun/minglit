part of 'event_application_wizard_page.dart';

class _VerificationStep extends ConsumerWidget {
  const _VerificationStep({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(eventApplicationControllerProvider(event));

    // For now, let's assume we find the first requirement
    final ticket = state.selectedTicket;
    if (ticket == null) return const Text('티켓을 먼저 선택해주세요.');

    final entryGroups = event.entryGroups ?? [];
    final linkedGroups = entryGroups
        .where((g) => ticket.targetEntryGroupIds.contains(g.id))
        .toList();

    final verifIds =
        linkedGroups.expand((g) => g.requiredVerificationIds).toSet().toList();

    if (verifIds.isEmpty) {
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

    // Fetch the verification definition
    final sortedIds = List<String>.from(verifIds)..sort();
    final idsString = sortedIds.join(',');
    final verifAsync = ref.watch(verificationsByIdsProvider(idsString));

    return MinglitAsyncValueWidget(
      value: verifAsync,
      data: (verifs) {
        if (verifs.isEmpty) return const Text('인증 정보를 불러올 수 없습니다.');
        final verif = verifs.first; // Handle first one for now

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verif.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (verif.description != null)
              Padding(
                padding: const EdgeInsets.only(top: MinglitSpacing.xxsmall),
                child: Text(
                  verif.description!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: MinglitSpacing.large),
            ...verif.formSchema.map(
              (field) => _buildFormField(context, ref, field),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormField(
    BuildContext context,
    WidgetRef ref,
    VerificationFormField field,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          if (field.type == 'file')
            Builder(
              builder: (context) {
                final user = ref.read(currentUserProvider);
                final userId = user?.id;
                if (userId == null) {
                  return const Text('로그인이 필요합니다.');
                }
                final pathPrefix = '$userId/applications/${event.id}';
                Log.d('📂 [Wizard] FilePicker pathPrefix: $pathPrefix');
                return MinglitFilePicker(
                  label: field.label,
                  hint: field.placeholder ?? '증빙 서류를 업로드해주세요',
                  fileType: FileType.any,
                  autoUpload: true,
                  uploadBucket: 'verification-proofs',
                  uploadPathPrefix: pathPrefix,
                  onUploadComplete: (urls) {
                    if (urls.isNotEmpty) {
                      ref
                          .read(
                            eventApplicationControllerProvider(
                              event,
                            ).notifier,
                          )
                          .updateVerificationData(field.key, urls.first);
                    } else {
                      ref
                          .read(
                            eventApplicationControllerProvider(
                              event,
                            ).notifier,
                          )
                          .updateVerificationData(field.key, null);
                    }
                  },
                  onFilesSelected: (files) {
                    // Handle local preview or validation if needed
                  },
                );
              },
            )
          else
            TextFormField(
              decoration: InputDecoration(
                hintText: field.placeholder ?? '${field.label}을(를) 입력하세요',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(
                      eventApplicationControllerProvider(event).notifier,
                    )
                    .updateVerificationData(field.key, value);
              },
            ),
        ],
      ),
    );
  }
}
