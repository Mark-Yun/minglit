import 'package:app_partner/src/utils/error_handler.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // 데이터 필드
  final Map<String, dynamic> _data = {
    'biz_type': 'individual',
  };
  XFile? _bizRegFile;
  XFile? _bankbookFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkExistingApplication(),
    );
  }

  Future<void> _checkExistingApplication() async {
    setState(() => _isLoading = true);
    final repository = ref.read(partnerRepositoryProvider);
    final app = await repository.getMyApplication();
    if (app != null && mounted) {
      // 이미 신청한 내역이 있다면 안내 화면으로 이동 (혹은 상태 표시)
      await _showStatusDialog(app.status);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _showStatusDialog(String status) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.partnerApplication_status_dialogTitle),
        content: Text(
          context.l10n.partnerApplication_status_dialogContent(status),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_button_confirm),
          ),
        ],
      ),
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
    if (_bizRegFile == null || _bankbookFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.partnerApplication_message_missingFiles),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final repository = ref.read(partnerRepositoryProvider);
      await repository.submitApplication(
        applicationData: _data,
        bizRegistrationFile: _bizRegFile!,
        bankbookFile: _bankbookFile!,
      );
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.partnerApplication_dialog_successTitle),
            content: Text(
              context.l10n.partnerApplication_dialog_successContent,
            ),
          ),
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
      appBar: AppBar(title: Text(context.l10n.partnerApplication_title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      context.l10n.partnerApplication_section_brand,
                    ),
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

                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      context.l10n.partnerApplication_section_biz,
                    ),
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

                    const SizedBox(height: 32),
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

                    const SizedBox(height: 32),
                    _buildSectionTitle(
                      context.l10n.partnerApplication_section_files,
                    ),
                    _buildFilePicker(
                      context.l10n.partnerApplication_label_bizReg,
                      _bizRegFile,
                      () async => _pickFile(true),
                    ),
                    const SizedBox(height: 12),
                    _buildFilePicker(
                      context.l10n.partnerApplication_label_bankbook,
                      _bankbookFile,
                      () async => _pickFile(false),
                    ),

                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(
                        context.l10n.partnerApplication_button_submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
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
      padding: const EdgeInsets.only(bottom: 16),
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
      padding: const EdgeInsets.only(bottom: 16),
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
    return ListTile(
      tileColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        file != null
            ? file.name
            : context.l10n.partnerApplication_hint_fileSelect,
        style: TextStyle(color: file != null ? Colors.blue : Colors.grey),
      ),
      trailing: const Icon(Icons.attach_file),
      onTap: onTap,
    );
  }
}
