import 'package:app_partner/src/features/verification/create_verification_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class CreateVerificationScreen extends ConsumerStatefulWidget {
  const CreateVerificationScreen({super.key, this.partnerId});

  final String? partnerId;

  @override
  ConsumerState<CreateVerificationScreen> createState() =>
      _CreateVerificationScreenState();
}

class _CreateVerificationScreenState
    extends ConsumerState<CreateVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _displayNameController;
  late TextEditingController _internalNameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _internalNameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _internalNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(createVerificationControllerProvider.notifier)
        .submit(widget.partnerId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증이 생성되었습니다.')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch state
    final state = ref.watch(createVerificationControllerProvider);
    final controller = ref.read(createVerificationControllerProvider.notifier);

    // Listen for errors
    ref.listen(createVerificationControllerProvider, (prev, next) {
      if (prev?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '새 인증 만들기',
        actions: [
          TextButton(
            onPressed: state.isSubmitting ? null : _onSubmit,
            child: Text(
              '저장',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: state.isSubmitting ? Colors.grey : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              children: [
                _buildBasicInfoSection(theme, controller),
                const SizedBox(height: MinglitSpacing.large),
                _buildFormBuilderSection(theme, state, controller),
              ],
            ),
          ),
          if (state.isSubmitting)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(
    ThemeData theme,
    CreateVerificationController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기본 정보',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: '인증 이름 (유저에게 표시)',
            hintText: '예: 골프 핸디캡 인증',
          ),
          onChanged: controller.updateDisplayName,
          validator: (value) =>
              value == null || value.isEmpty ? '이름을 입력해주세요.' : null,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        TextFormField(
          controller: _internalNameController,
          decoration: const InputDecoration(
            labelText: '관리용 이름 (내부 식별용)',
            hintText: '예: Golf Handicap 2024',
          ),
          onChanged: controller.updateInternalName,
          validator: (value) =>
              value == null || value.isEmpty ? '관리용 이름을 입력해주세요.' : null,
        ),
        const SizedBox(height: MinglitSpacing.medium),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '설명',
            hintText: '유저가 인증할 때 참고할 설명을 적어주세요.',
          ),
          onChanged: controller.updateDescription,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildFormBuilderSection(
    ThemeData theme,
    CreateVerificationState state,
    CreateVerificationController controller,
  ) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '입력 양식 설정',
              style: theme.textTheme.titleLarge,
            ),
            PopupMenuButton<String>(
              onSelected: controller.addField,
              icon: Icon(Icons.add_circle, color: colorScheme.primary),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'text', child: Text('텍스트 입력')),
                const PopupMenuItem(value: 'number', child: Text('숫자 입력')),
                const PopupMenuItem(value: 'file', child: Text('파일 업로드')),
                const PopupMenuItem(value: 'date', child: Text('날짜 선택')),
              ],
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.small),
        if (state.fields.isEmpty)
          Container(
            padding: const EdgeInsets.all(MinglitSpacing.xlarge),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              '+ 버튼을 눌러 필드를 추가하세요',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.fields.length,
            onReorder: (oldIndex, newIndex) {
              // TODO(dev): Implement reorder in controller if needed
              // For now, simple index swap logic or just ignore
            },
            itemBuilder: (context, index) {
              final field = state.fields[index];
              return _FieldEditorCard(
                key: ValueKey(field.key),
                field: field,
                onUpdate: (updated) => controller.updateField(index, updated),
                onDelete: () => controller.removeField(index),
              );
            },
          ),
      ],
    );
  }
}

class _FieldEditorCard extends StatefulWidget {
  const _FieldEditorCard({
    required this.field,
    required this.onUpdate,
    required this.onDelete,
    super.key,
  });

  final VerificationFormField field;
  final ValueChanged<VerificationFormField> onUpdate;
  final VoidCallback onDelete;

  @override
  State<_FieldEditorCard> createState() => _FieldEditorCardState();
}

class _FieldEditorCardState extends State<_FieldEditorCard> {
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
  }

  @override
  void didUpdateWidget(covariant _FieldEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.label != widget.field.label) {
      _labelController.text = widget.field.label;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final typeIcon = switch (widget.field.type) {
      'text' => Icons.text_fields,
      'number' => Icons.numbers,
      'file' => Icons.upload_file,
      'date' => Icons.calendar_today,
      _ => Icons.help_outline,
    };

    final typeLabel = switch (widget.field.type) {
      'text' => '텍스트',
      'number' => '숫자',
      'file' => '파일',
      'date' => '날짜',
      _ => widget.field.type,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      // Card theme handles elevation and color automatically
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: widget.onDelete,
                ),
                Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: '라벨 (질문 내용)',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      widget.onUpdate(widget.field.copyWith(label: val));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: widget.field.required,
                      activeColor: colorScheme.primary,
                      onChanged: (val) {
                        widget.onUpdate(
                          widget.field.copyWith(required: val ?? false),
                        );
                      },
                    ),
                    Text('필수', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
