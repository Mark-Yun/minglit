import 'dart:async';

import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventApplicationWizardScreen extends ConsumerWidget {
  const EventApplicationWizardScreen({
    required this.eventId,
    this.ticketId,
    super.key,
  });

  final String eventId;
  final String? ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailControllerProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('참여 신청'),
        leading: const CloseButton(),
      ),
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) => _WizardBody(event: event, initialTicketId: ticketId),
      ),
    );
  }
}

class _WizardBody extends ConsumerStatefulWidget {
  const _WizardBody({required this.event, this.initialTicketId});

  final Event event;
  final String? initialTicketId;

  @override
  ConsumerState<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends ConsumerState<_WizardBody> {
  @override
  void initState() {
    super.initState();
    // Initialize controller with selected ticket if provided
    if (widget.initialTicketId != null) {
      final ticket = widget.event.tickets?.firstWhere(
        (t) => t.id == widget.initialTicketId,
      );
      if (ticket != null) {
        unawaited(
          Future.microtask(() {
            ref
                .read(eventApplicationControllerProvider(widget.event).notifier)
                .selectTicket(ticket);
          }),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventApplicationControllerProvider(widget.event));
    final controller = ref.read(
      eventApplicationControllerProvider(widget.event).notifier,
    );

    // Listen for success
    ref.listen(eventApplicationControllerProvider(widget.event), (_, next) {
      if (next.status == EventApplicationStatus.success) {
        context
          ..pop()
          ..showMinglitSuccess('신청이 완료되었습니다! 파트너 심사 후 알려드릴게요.');
      }
      if (next.status == EventApplicationStatus.error) {
        handleMinglitError(context, next.errorMessage!);
      }
    });

    return Column(
      children: [
        // 1. Progress Indicator
        _StepIndicator(currentStep: state.step),

        // 2. Step Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: state.step == EventApplicationStep.verification
                ? _VerificationStep(event: widget.event)
                : _PaymentStep(event: widget.event),
          ),
        ),

        // 3. Footer Buttons
        _Footer(
          state: state,
          onPrev: controller.previousStep,
          onNext: controller.nextStep,
          onSubmit: controller.submitApplication,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final EventApplicationStep currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCircle(
            context,
            '1',
            '인증',
            currentStep == EventApplicationStep.verification,
          ),
          Container(
            width: MinglitSpacing.xlarge + MinglitSpacing.small, // 40
            height: 2,
            color: theme.colorScheme.outlineVariant,
            margin: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
            ),
          ),
          _buildCircle(
            context,
            '2',
            '결제',
            currentStep == EventApplicationStep.payment,
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(
    BuildContext context,
    String num,
    String label,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Column(
      children: [
        CircleAvatar(
          radius: MinglitSpacing
              .medium, // Changed from 12 to 16 for better alignment with tokens
          backgroundColor: color,
          child: Text(
            num,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: MinglitSpacing.xsmall),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}

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

    final verifIds = linkedGroups
        .expand((g) => g.requiredVerificationIds)
        .toSet()
        .toList();

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
            MinglitFilePicker(
              label: field.label,
              hint: field.placeholder ?? '증빙 서류를 업로드해주세요',
              fileType: FileType.any,
              autoUpload: true,
              uploadBucket: 'verification_docs',
              uploadPathPrefix: 'applications/${event.id}',
              onUploadComplete: (urls) {
                if (urls.isNotEmpty) {
                  ref
                      .read(eventApplicationControllerProvider(event).notifier)
                      .updateVerificationData(field.key, urls.first);
                } else {
                  ref
                      .read(eventApplicationControllerProvider(event).notifier)
                      .updateVerificationData(field.key, null);
                }
              },
              onFilesSelected: (files) {
                // Handle local preview or validation if needed
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
                    .read(eventApplicationControllerProvider(event).notifier)
                    .updateVerificationData(field.key, value);
              },
            ),
        ],
      ),
    );
  }
}

class _PaymentStep extends ConsumerWidget {
  const _PaymentStep({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(eventApplicationControllerProvider(event));
    final ticket = state.selectedTicket;

    if (ticket == null) return const Text('티켓 정보가 없습니다.');

    final formatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 상세',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(MinglitRadius.small),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ticket.name),
                  Text('${formatter.format(ticket.price)}원'),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최종 결제 금액',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${formatter.format(ticket.price)}원',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.xlarge),
        Text(
          '• 파트너 심사 반려 시 100% 환불됩니다.\n• 결제 완료 후 심사에는 최대 24시간이 소요될 수 있습니다.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  final EventApplicationState state;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstStep = state.step == EventApplicationStep.verification;
    final isSubmitting = state.status == EventApplicationStatus.submitting;

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onPrev,
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : (isFirstStep ? onNext : onSubmit),
                child: isSubmitting
                    ? const MinglitCircularProgressIndicator(
                        size: 20,
                      )
                    : Text(isFirstStep ? '다음' : '결제하고 신청하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
