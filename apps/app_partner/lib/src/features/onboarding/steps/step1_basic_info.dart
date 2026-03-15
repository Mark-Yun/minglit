import 'package:app_partner/src/features/onboarding/partner_apply_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step1BasicInfo extends ConsumerWidget {
  const Step1BasicInfo({super.key});

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
            context.l10n.partnerApplication_field_brandName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.brandName,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_brandName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            onChanged: (val) => notifier.updateField('brandName', val),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partnerApplication_field_intro,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          TextFormField(
            initialValue: state.introduction,
            decoration: InputDecoration(
              hintText: context.l10n.partnerApplication_hint_intro,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
            ),
            maxLines: 4,
            onChanged: (val) => notifier.updateField('introduction', val),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            '프로필 이미지 (선택)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          _ProfileImagePicker(
            imagePath: state.profileImagePath,
            imageFile: state.profileImageFile,
            onPick: notifier.uploadProfileImage,
          ),
        ],
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  const _ProfileImagePicker({
    required this.onPick,
    this.imagePath,
    this.imageFile,
  });

  final String? imagePath;
  final XFile? imageFile; // XFile?
  final void Function(XFile file) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFile != null || imagePath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
              child: Container(
                width: 100,
                height: 100,
                color: MinglitColors.surface,
                child: const Center(
                  child: Icon(Icons.image, color: MinglitColors.primary),
                ),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final picker = ImagePicker();
            final file = await picker.pickImage(source: ImageSource.gallery);
            if (file != null) onPick(file);
          },
          icon: const Icon(Icons.image_outlined, color: MinglitColors.primary),
          label: Text(
            imagePath != null || imageFile != null ? '이미지 변경' : '이미지 선택',
            // ignore: minglit_no_hardcoded_text_style, button label color
            style: const TextStyle(color: MinglitColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: MinglitColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MinglitRadius.input),
            ),
          ),
        ),
      ],
    );
  }
}
