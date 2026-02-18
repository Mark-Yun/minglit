import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerApplicationPage extends ConsumerStatefulWidget {
  const PartnerApplicationPage({super.key});

  @override
  ConsumerState<PartnerApplicationPage> createState() =>
      _PartnerApplicationPageState();
}

class _PartnerApplicationPageState
    extends ConsumerState<PartnerApplicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // 브랜드 정보 controllers
  final Map<String, dynamic> _data = {'biz_type': 'individual'};
  XFile? _bizRegFile;
  XFile? _bankbookFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkExistingApplication(),
    );
  }

  Future<void> _checkExistingApplication() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(partnerRepositoryProvider);
      final app = await repository.getMyApplication();
      if (app != null && mounted) {
        // 이미 신청한 내역이 있다면 안내 화면으로 이동 (혹은 상태 표시)
        await _showStatusDialog(app.status);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showStatusDialog(String status) async {
    await context.showMinglitAlert(
      title: context.l10n.partnerApplication_status_dialogTitle,
      message: context.l10n.partnerApplication_status_dialogContent(status),
    );
  }

  Future<void> _pickFile(bool isBizReg) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        if (isBizReg) {
          _bizRegFile = file;
        } else {
          _bankbookFile = file;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final bizRegFile = _bizRegFile;
    final bankbookFile = _bankbookFile;
    if (bizRegFile == null || bankbookFile == null) {
      context.showMinglitWarning(
        context.l10n.partnerApplication_message_missingFiles,
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(partnerRepositoryProvider);
      await repository.submitApplication(
        applicationData: _data,
        bizRegistrationFile: bizRegFile,
        bankbookFile: bankbookFile,
      );
      if (mounted) {
        await context.showMinglitAlert(
          title: context.l10n.partnerApplication_dialog_successTitle,
          message: context.l10n.partnerApplication_dialog_successContent,
        );
      }
    } on Object catch (e, st) {
      if (mounted) {
        handleMinglitError(context, e, st);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: context.l10n.partnerApplication_title,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context.l10n.partnerApplication_section_brand),
              _buildTextField(
                'brand_name',
                context.l10n.partnerApplication_field_brandName,
                context.l10n.partnerApplication_hint_brandName,
              ),
              _buildTextField(
                'introduction',
                context.l10n.partnerApplication_field_intro,
                context.l10n.partnerApplication_hint_intro,
                maxLines: 3,
              ),
              _buildTextField(
                'address',
                context.l10n.partnerApplication_field_address,
                context.l10n.partnerApplication_hint_address,
              ),
              _buildTextField(
                'contact_phone',
                context.l10n.partnerApplication_field_phone,
                context.l10n.partnerApplication_hint_phone,
              ),
              _buildTextField(
                'contact_email',
                context.l10n.partnerApplication_field_email,
                context.l10n.partnerApplication_hint_email,
              ),

              const SizedBox(height: MinglitSpacing.xlarge),
              _buildSectionTitle(context.l10n.partnerApplication_section_biz),
              _buildBizTypeDropdown(),
              _buildTextField(
                'biz_name',
                context.l10n.partnerApplication_field_bizName,
                context.l10n.partnerApplication_hint_bizName,
              ),
              _buildTextField(
                'biz_number',
                context.l10n.partnerApplication_field_bizNumber,
                context.l10n.partnerApplication_hint_bizNumber,
              ),
              _buildTextField(
                'representative_name',
                context.l10n.partnerApplication_field_repName,
                context.l10n.partnerApplication_hint_repName,
              ),

              const SizedBox(height: MinglitSpacing.xlarge),
              _buildSectionTitle(
                context.l10n.partnerApplication_section_account,
              ),
              _buildTextField(
                'bank_name',
                context.l10n.partnerApplication_field_bankName,
                context.l10n.partnerApplication_hint_bankName,
              ),
              _buildTextField(
                'account_number',
                context.l10n.partnerApplication_field_accountNum,
                context.l10n.partnerApplication_hint_accountNum,
              ),
              _buildTextField(
                'account_holder',
                context.l10n.partnerApplication_field_holder,
                // Reusing repName hint ("성함")
                context.l10n.partnerApplication_hint_repName,
              ),

              const SizedBox(height: MinglitSpacing.xlarge),
              _buildSectionTitle(context.l10n.partnerApplication_section_files),
              _buildFilePicker(
                context.l10n.partnerApplication_label_bizReg,
                _bizRegFile,
                () async => _pickFile(true),
              ),
              const SizedBox(height: MinglitSpacing.small),
              _buildFilePicker(
                context.l10n.partnerApplication_label_bankbook,
                _bankbookFile,
                () async => _pickFile(false),
              ),

              const SizedBox(height: MinglitSpacing.xlarge * 1.5),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const MinglitCircularProgressIndicator(size: 20)
                    : Text(context.l10n.partnerApplication_button_submit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: TextFormField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => (v == null || v.isEmpty)
            ? context.l10n.partnerApplication_error_required
            : null,
        onSaved: (v) => _data[key] = v,
      ),
    );
  }

  Widget _buildBizTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: DropdownButtonFormField<String>(
        initialValue: _data['biz_type'] as String?,
        decoration: InputDecoration(
          labelText: context.l10n.partnerApplication_field_bizType,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: 'individual',
            child: Text(context.l10n.partnerApplication_option_individual),
          ),
          DropdownMenuItem(
            value: 'corporate',
            child: Text(context.l10n.partnerApplication_option_corporate),
          ),
        ],
        onChanged: (v) => setState(() => _data['biz_type'] = v),
      ),
    );
  }

  Widget _buildFilePicker(String label, XFile? file, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      tileColor: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        file != null
            ? file.name
            : context.l10n.partnerApplication_hint_fileSelect,
        style: theme.textTheme.labelSmall?.copyWith(
          color: file != null
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
      ),
      trailing: const Icon(Icons.attach_file),
      onTap: onTap,
    );
  }
}
