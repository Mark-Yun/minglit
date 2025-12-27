import 'package:flutter/material.dart';

class CareerVerificationForm extends StatefulWidget {
  // 초기값 추가

  const CareerVerificationForm({
    required this.onChanged,
    super.key,
    this.initialData,
  });
  final void Function(Map<String, dynamic> data) onChanged;
  final Map<String, dynamic>? initialData;

  @override
  State<CareerVerificationForm> createState() => _CareerVerificationFormState();
}

class _CareerVerificationFormState extends State<CareerVerificationForm> {
  late final TextEditingController _companyController;
  late final TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    // 초기값이 있으면 채워줌
    _companyController = TextEditingController(
      text: widget.initialData?['company_name'] as String? ?? '',
    );
    _displayController = TextEditingController(
      text: widget.initialData?['display_name'] as String? ?? '',
    );

    // 초기 데이터가 있다면 한번 호출하여 부모 위젯과 동기화
    if (widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _update());
    }
  }

  void _update() {
    widget.onChanged({
      'company_name': _companyController.text,
      'display_name': _displayController.text,
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _displayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '직장 정보 입력',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        const Text('실제 직장명', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _companyController,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: '예: 삼성전자 (인증 후 수정 불가)',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (_) => _update(),
        ),
        const SizedBox(height: 20),

        const Text('노출용 직장명', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _displayController,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '예: IT 대기업, 반도체 제조 등',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onChanged: (_) => _update(),
        ),
        const SizedBox(height: 8),
        const Text(
          '타인에게 보여질 이름입니다. 실제와 다를 경우 심사에서 반려될 수 있습니다.',
          style: TextStyle(color: Colors.blue, fontSize: 12),
        ),
      ],
    );
  }
}
