import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class TicketTemplateCreatePage extends StatefulWidget {
  const TicketTemplateCreatePage({super.key});

  @override
  State<TicketTemplateCreatePage> createState() =>
      _TicketTemplateCreatePageState();
}

class _TicketTemplateCreatePageState extends State<TicketTemplateCreatePage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _quantityController = TextEditingController(text: '20');
  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('티켓 이름을 입력해주세요.')),
      );
      return;
    }

    final ticket = Ticket(
      id: '', // Temporary ID
      name: _nameController.text,
      price: int.tryParse(_priceController.text) ?? 0,
      quantity: int.tryParse(_quantityController.text) ?? 0,
      conditions: {
        'gender': _selectedGender,
      }..removeWhere((k, v) => v == null),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(ticket);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기본 티켓 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '티켓 이름',
                hintText: '예: 얼리버드 남성',
              ),
              autofocus: true,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '가격',
                suffixText: '원',
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '기본 수량',
                suffixText: '매',
              ),
            ),
            const SizedBox(height: MinglitSpacing.large),
            const Text('구매 가능 성별'),
            const SizedBox(height: MinglitSpacing.small),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: _selectedGender == null,
                  onSelected: (_) => setState(() => _selectedGender = null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('남성'),
                  selected: _selectedGender == 'male',
                  onSelected: (_) => setState(() => _selectedGender = 'male'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('여성'),
                  selected: _selectedGender == 'female',
                  onSelected: (_) => setState(() => _selectedGender = 'female'),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('추가하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
