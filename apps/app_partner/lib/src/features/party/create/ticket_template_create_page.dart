import 'package:app_partner/src/utils/l10n_ext.dart';
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
  int _price = 0;
  int _quantity = 20;
  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
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
      price: _price,
      quantity: _quantity,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ticketCreate_title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.ticketCreate_label_name,
                hintText: context.l10n.ticketCreate_hint_name,
              ),
              autofocus: true,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: NumberStepperInput(
                    label: context.l10n.ticketCreate_label_price,
                    value: _price,
                    step: 1000,
                    suffixText: '원',
                    onChanged: (val) => setState(() => _price = val),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: NumberStepperInput(
                    label: context.l10n.ticketCreate_label_quantity,
                    value: _quantity,
                    min: 1,
                    max: 999,
                    suffixText: '매',
                    onChanged: (val) => setState(() => _quantity = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),
            Text(
              context.l10n.ticketCreate_label_gender,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Row(
              children: [
                ChoiceChip(
                  label: Text(context.l10n.entryGroup_option_any),
                  selected: _selectedGender == null,
                  onSelected: (_) => setState(() => _selectedGender = null),
                  selectedColor: colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.l10n.entryGroup_option_male),
                  selected: _selectedGender == 'male',
                  onSelected: (_) => setState(() => _selectedGender = 'male'),
                  selectedColor: colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.l10n.entryGroup_option_female),
                  selected: _selectedGender == 'female',
                  onSelected: (_) => setState(() => _selectedGender = 'female'),
                  selectedColor: colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(context.l10n.ticketCreate_button_add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
