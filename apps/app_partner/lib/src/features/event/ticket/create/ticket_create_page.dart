import 'package:app_partner/src/features/event/ticket/create/ticket_create_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class TicketCreatePage extends ConsumerStatefulWidget {
  const TicketCreatePage({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<TicketCreatePage> createState() => _TicketCreatePageState();
}

class _TicketCreatePageState extends ConsumerState<TicketCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _quantityController = TextEditingController(text: '10');
  final _minBirthYearController = TextEditingController();
  final _maxBirthYearController = TextEditingController();

  String? _selectedGender; // null, 'male', 'female'

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minBirthYearController.dispose();
    _maxBirthYearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();

    try {
      await ref
          .read(ticketCreateControllerProvider.notifier)
          .createTicket(
            eventId: widget.eventId,
            name: _nameController.text,
            price: int.tryParse(_priceController.text) ?? 0,
            quantity: int.tryParse(_quantityController.text) ?? 0,
            gender: _selectedGender,
            minBirthYear: int.tryParse(_minBirthYearController.text),
            maxBirthYear: int.tryParse(_maxBirthYearController.text),
          );

      final state = ref.read(ticketCreateControllerProvider);

      if (!state.hasError && mounted) {
        context.pop(); // Return to Event Detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('티켓이 생성되었습니다.')),
        );
      } else if (state.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('생성 실패: ${state.error}')),
        );
      }
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(ticketCreateControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('새 티켓 만들기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '티켓 이름',
                  hintText: '예: 얼리버드 남성 티켓',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? '티켓 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: MinglitSpacing.large),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '가격',
                        suffixText: '원',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? '가격을 입력해주세요.' : null,
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '발행 수량',
                        suffixText: '매',
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? '수량을 입력해주세요.' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text('성별 제한 (선택)', style: theme.textTheme.titleMedium),
              const SizedBox(height: MinglitSpacing.small),
              Row(
                children: [
                  _GenderSelectionChip(
                    label: '제한 없음',
                    isSelected: _selectedGender == null,
                    onTap: () => setState(() => _selectedGender = null),
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  _GenderSelectionChip(
                    label: '남성 전용',
                    isSelected: _selectedGender == 'male',
                    onTap: () => setState(() => _selectedGender = 'male'),
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  _GenderSelectionChip(
                    label: '여성 전용',
                    isSelected: _selectedGender == 'female',
                    onTap: () => setState(() => _selectedGender = 'female'),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text('나이 제한 (출생년도, 선택)', style: theme.textTheme.titleMedium),
              const SizedBox(height: MinglitSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minBirthYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '최소 년도',
                        hintText: '예: 1990',
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.medium,
                    ),
                    child: Text('~'),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _maxBirthYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '최대 년도',
                        hintText: '예: 2000',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.xlarge),

              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: const Text('티켓 생성 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderSelectionChip extends StatelessWidget {
  const _GenderSelectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
