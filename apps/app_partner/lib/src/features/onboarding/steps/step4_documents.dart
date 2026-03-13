import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step4Documents extends ConsumerWidget {
  const Step4Documents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerApplyControllerProvider);
    final notifier = ref.read(partnerApplyControllerProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.partnerApplication_label_bizReg,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          _DocumentPicker(
            filePath: state.bizRegistrationPath,
            file: state.bizRegistrationFile,
            onPick: notifier.uploadBizRegistration,
            hint: context.l10n.partnerApplication_hint_fileSelect,
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partnerApplication_label_bankbook,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          _DocumentPicker(
            filePath: state.bankbookPath,
            file: state.bankbookFile,
            onPick: notifier.uploadBankbook,
            hint: context.l10n.partnerApplication_hint_fileSelect,
          ),
        ],
      ),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({
    required this.onPick,
    required this.hint,
    this.filePath,
    this.file,
  });

  final String? filePath;
  final XFile? file;
  final String hint;
  final void Function(XFile file) onPick;

  @override
  Widget build(BuildContext context) {
    final hasFile = filePath != null || file != null;
    final fileName = file?.name ?? (filePath?.split('/').last ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFile) ...[
          Container(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              border: Border.all(color: MinglitColors.success),
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              color: MinglitColors.success.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: MinglitColors.success,
                  size: MinglitIconSize.medium,
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MinglitColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
        OutlinedButton.icon(
          onPressed: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: ImageSource.gallery,
            );
            if (pickedFile != null) onPick(pickedFile);
          },
          icon: const Icon(Icons.upload_file, color: MinglitColors.primary),
          label: Text(
            hasFile ? '파일 변경' : hint,
            // ignore: minglit_no_hardcoded_text_style, button label color
            style: const TextStyle(color: MinglitColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: MinglitColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
            ),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ],
    );
  }
}
