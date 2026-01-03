import 'package:app_partner/src/features/event/create/event_create_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventCreatePage extends ConsumerStatefulWidget {
  const EventCreatePage({required this.partyId, super.key});

  final String partyId;

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<EventCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '20');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();

    try {
      // Combine Date + Time
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      var endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Handle overnight events
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }

      await ref
          .read(eventCreateControllerProvider.notifier)
          .createEvent(
            partyId: widget.partyId,
            startTime: startDateTime,
            endTime: endDateTime,
            maxParticipants:
                int.tryParse(_maxParticipantsController.text) ?? 20,
            title: _titleController.text.isEmpty ? null : _titleController.text,
          );

      final state = ref.read(eventCreateControllerProvider);
      if (!state.hasError && mounted) {
        context.pop(); // Go back to Party Detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회차가 생성되었습니다.')),
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
    final state = ref.watch(eventCreateControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '새 회차(이벤트) 만들기'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '회차 제목 (선택)',
                  hintText: '예: 할로윈 특집 (미입력시 파티 제목 사용)',
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),

              Text('일시', style: theme.textTheme.titleMedium),
              const SizedBox(height: MinglitSpacing.small),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(_selectedDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('시작: ${_startTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('종료: ${_endTime.format(context)}'),
                      trailing: const Icon(Icons.access_time_filled),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.large),

              TextFormField(
                controller: _maxParticipantsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '최대 정원',
                  suffixText: '명',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '정원을 입력해주세요';
                  if (int.tryParse(value) == null) return '숫자만 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: MinglitSpacing.xlarge),

              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: const Text('회차 생성하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
