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
        title: const Text('신청 현황'),
        content: Text('현재 가입 신청이 [$status] 상태입니다. 심사가 완료될 때까지 기다려 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필수 서류를 모두 업로드해 주세요.')));
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
          builder: (context) => const AlertDialog(
            title: Text('신청 완료'),
            content: Text('입점 신청이 제출되었습니다. 심사 결과는 이메일로 안내해 드립니다.'),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('제출 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('파트너 입점 신청')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('1. 브랜드 정보'),
                    _buildTextField('brand_name', '브랜드/매장명', '예: 밍글릿 강남점'),
                    _buildTextField(
                      'introduction',
                      '소개글',
                      '사장님과 매장을 소개해 주세요.',
                      maxLines: 3,
                    ),
                    _buildTextField('address', '주소', '파티가 열릴 매장 주소'),
                    _buildTextField('contact_phone', '연락처', '010-0000-0000'),
                    _buildTextField(
                      'contact_email',
                      '이메일',
                      'partner@example.com',
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('2. 사업자 정보'),
                    _buildBizTypeDropdown(),
                    _buildTextField('biz_name', '사업자명', '사업자 등록증상 이름'),
                    _buildTextField('biz_number', '사업자 번호', '000-00-00000'),
                    _buildTextField('representative_name', '대표자명', '성함'),

                    const SizedBox(height: 32),
                    _buildSectionTitle('3. 정산 계좌 정보'),
                    _buildTextField('bank_name', '은행명', '예: 신한은행'),
                    _buildTextField('account_number', '계좌번호', '숫자만 입력'),
                    _buildTextField('account_holder', '예금주', '성함'),

                    const SizedBox(height: 32),
                    _buildSectionTitle('4. 서류 첨부'),
                    _buildFilePicker(
                      '사업자등록증',
                      _bizRegFile,
                      () async => _pickFile(true),
                    ),
                    const SizedBox(height: 12),
                    _buildFilePicker(
                      '통장 사본',
                      _bankbookFile,
                      () async => _pickFile(false),
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '입점 신청하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
        validator: (v) => (v == null || v.isEmpty) ? '필수 입력 항목입니다.' : null,
        onSaved: (v) => _data[key] = v,
      ),
    );
  }

  Widget _buildBizTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _data['biz_type'] as String?,
        decoration: const InputDecoration(
          labelText: '사업자 유형',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 'individual', child: Text('개인 사업자')),
          DropdownMenuItem(value: 'corporate', child: Text('법인 사업자')),
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
        file != null ? file.name : '파일을 선택해 주세요.',
        style: TextStyle(color: file != null ? Colors.blue : Colors.grey),
      ),
      trailing: const Icon(Icons.attach_file),
      onTap: onTap,
    );
  }
}
