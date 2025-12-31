import 'dart:io';

import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCreateScreen extends ConsumerStatefulWidget {
  const PartyCreateScreen({super.key});

  @override
  ConsumerState<PartyCreateScreen> createState() => _PartyCreateScreenState();
}

class _PartyCreateScreenState extends ConsumerState<PartyCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _quillController = quill.QuillController.basic();
  final _minCountController = TextEditingController(text: '10');
  final _maxCountController = TextEditingController(text: '30');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _kakaoController = TextEditingController();

  // State
  XFile? _selectedImage;

  // Initial Data Loaded Flag
  bool _isDataLoaded = false;

  // FocusNode for Editor
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _minCountController.dispose();
    _maxCountController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _kakaoController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final descriptionJson = {
      'ops': _quillController.document.toDelta().toJson(),
    };

    final coordinator = PartyCreateCoordinator(context);
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();

    try {
      await ref
          .read(partyCreateControllerProvider.notifier)
          .createParty(
            title: _titleController.text,
            description: descriptionJson,
            minConfirmedCount: int.tryParse(_minCountController.text) ?? 0,
            maxParticipants: int.tryParse(_maxCountController.text) ?? 0,
            contactPhone: _phoneController.text,
            contactEmail: _emailController.text,
            contactKakao: _kakaoController.text.isNotEmpty
                ? _kakaoController.text
                : null,
            imageFile: _selectedImage,
          );

      final state = ref.read(partyCreateControllerProvider);
      if (state.status.hasError) {
        coordinator.onError(state.status.error! as Exception);
      } else {
        coordinator.onPartyCreated();
      }
    } on Exception catch (e) {
      coordinator.onError(e);
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final state = ref.watch(partyCreateControllerProvider);
    final controller = ref.read(partyCreateControllerProvider.notifier);
    final verificationsAsync = ref.watch(partyVerificationTypesProvider);
    final partnerInfoAsync = ref.watch(currentPartnerInfoProvider);

    // Load initial data once
    ref.listen(currentPartnerInfoProvider, (previous, next) {
      if (next.value != null && !_isDataLoaded) {
        final partner = next.value!;
        if (partner.contactPhone != null) {
          _phoneController.text = partner.contactPhone!;
        }
        if (partner.contactEmail != null) {
          _emailController.text = partner.contactEmail!;
        }
        setState(() {
          _isDataLoaded = true;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('파티 기획하기'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 파티 제목
              const _SectionTitle('파티 제목'),
              TextFormField(
                controller: _titleController,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
                decoration: const InputDecoration(
                  hintText: '예: 강남역 불금 와인 파티',
                ),
                validator: controller.validateTitle,
              ),
              const SizedBox(height: MinglitSpacing.large),

              // 2. 파티 설명
              const _SectionTitle('상세 설명'),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: MinglitQuillTheme.editorDecoration(context)
                    .copyWith(
                      border: Border.all(
                        color: state.descriptionError != null
                            ? colorScheme.error
                            : colorScheme.outlineVariant,
                        width: state.descriptionError != null ? 2 : 1,
                      ),
                    ),
                child: Column(
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController,
                      config: MinglitQuillTheme.toolbarConfig(context),
                    ),
                    Container(
                      height: 1,
                      color: state.descriptionError != null
                          ? colorScheme.error
                          : colorScheme.outlineVariant,
                    ),
                    SizedBox(
                      height: 250,
                      child: DefaultTextStyle(
                        style: theme.textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.normal,
                          color: MinglitColors.textPrimary,
                        ),
                        child: quill.QuillEditor.basic(
                          controller: _quillController,
                          focusNode: _editorFocusNode,
                          config: MinglitQuillTheme.editorConfig(
                            context,
                            placeholder: '파티의 분위기, 제공되는 음식, 음악 등을 자유롭게 꾸며보세요!',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.descriptionError != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: MinglitSpacing.xsmall,
                    left: MinglitSpacing.small,
                  ),
                  child: Text(
                    state.descriptionError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: MinglitSpacing.large),

              // 3. 커버 이미지
              const _SectionTitle('커버 이미지'),
              ClipRRect(
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                child: Material(
                  color: colorScheme.surface,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(MinglitRadius.card),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: kIsWeb
                                    ? NetworkImage(_selectedImage!.path)
                                    : FileImage(File(_selectedImage!.path))
                                          as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: colorScheme.secondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: MinglitSpacing.small),
                                Text(
                                  '터치하여 커버 이미지를 등록하세요',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(
                                          alpha: 0.5,
                                        ),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),

              // 4. 인원 설정
              const _SectionTitle('모집 인원'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '최소 확정',
                        suffixText: '명',
                      ),
                      validator: controller.validateCapacity,
                    ),
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '최대 정원',
                        suffixText: '명',
                      ),
                      validator: (v) => controller.validateMaxCapacity(
                        v,
                        _minCountController.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.small),
              Container(
                padding: const EdgeInsets.all(MinglitSpacing.small),
                child: Column(
                  children: [
                    _buildPolicyRow(
                      context,
                      '파티 3일 전까지 최소 확정 인원에 미달한 경우 파티는 취소되고 자동 환불됩니다.',
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    _buildPolicyRow(
                      context,
                      '최대 정원에 도달할 경우 티켓 판매가 즉시 자동 종료됩니다.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),

              // 5. 문의 연락처 (Auto-filled)
              const _SectionTitle('문의 연락처'),
              if (partnerInfoAsync.isLoading)
                Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.small),
                  child: Text(
                    '파트너 정보 불러오는 중...',
                    style: MinglitTextStyles.infoText(context),
                  ),
                ),

              // Phone
              _ContactSelectionRow(
                methodKey: 'phone',
                isSelected: state.enabledContactMethods.contains('phone'),
                onToggle: () => controller.toggleContactMethod('phone'),
                child: TextFormField(
                  controller: _phoneController,
                  enabled: state.enabledContactMethods.contains('phone'),
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.medium,
                      vertical: MinglitSpacing.medium,
                    ),
                    prefixIcon: Icon(Icons.phone, size: 18),
                  ),
                  validator: (v) =>
                      state.enabledContactMethods.contains('phone')
                      ? controller.validatePhone(v)
                      : null,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),

              // Email
              _ContactSelectionRow(
                methodKey: 'email',
                isSelected: state.enabledContactMethods.contains('email'),
                onToggle: () => controller.toggleContactMethod('email'),
                child: TextFormField(
                  controller: _emailController,
                  enabled: state.enabledContactMethods.contains('email'),
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.medium,
                      vertical: MinglitSpacing.medium,
                    ),
                    prefixIcon: Icon(Icons.email, size: 18),
                  ),
                  validator: (v) =>
                      state.enabledContactMethods.contains('email')
                      ? controller.validateEmail(v)
                      : null,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),

              // Kakao Link
              _ContactSelectionRow(
                methodKey: 'kakao',
                isSelected: state.enabledContactMethods.contains('kakao'),
                onToggle: () => controller.toggleContactMethod('kakao'),
                child: TextFormField(
                  controller: _kakaoController,
                  enabled: state.enabledContactMethods.contains('kakao'),
                  decoration: const InputDecoration(
                    labelText: '오픈카카오톡 링크 (선택)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.medium,
                      vertical: MinglitSpacing.medium,
                    ),
                    hintText: 'https://open.kakao.com/o/...',
                    prefixIcon: Icon(Icons.chat_bubble_outline, size: 18),
                    helperText: '참가자들과 소통할 오픈채팅방 링크를 입력해주세요.',
                  ),
                ),
              ),
              // Error message placeholder to prevent layout shift
              SizedBox(
                height: MinglitSpacing.large,
                child: AnimatedSwitcher(
                  duration: MinglitAnimation.fast,
                  child: state.enabledContactMethods.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: MinglitSpacing.small,
                            ),
                            child: Text(
                              '최소 한 개의 연락처를 선택해야 합니다.',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),

              // 6. 참가 자격 (인증)
              const _SectionTitle('참가 자격 (인증)'),
              verificationsAsync.when(
                data: (verifications) {
                  if (verifications.isEmpty) {
                    return Text(
                      '사용 가능한 인증이 없습니다.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: verifications.length,
                    itemBuilder: (context, index) {
                      final v = verifications[index];
                      final isSelected = state.selectedVerificationIds.contains(
                        v.id,
                      );
                      return VerificationSelectCard(
                        verification: v,
                        isSelected: isSelected,
                        onTap: () => ref
                            .read(partyCreateControllerProvider.notifier)
                            .toggleVerification(v.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('인증 목록 로드 실패: $e'),
              ),

              const SizedBox(height: MinglitSpacing.xlarge),

              // 하단 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.status.isLoading ? null : _submit,
                  child: const Text('파티 생성 완료'),
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary, // Using Midnight Navy from theme
        ),
      ),
    );
  }
}

Widget _buildPolicyRow(BuildContext context, String text) {
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline,
        size: 14,
        color: colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: MinglitSpacing.small),
      Expanded(
        child: Text(
          text,
          style: MinglitTextStyles.infoText(context),
        ),
      ),
    ],
  );
}

class _ContactSelectionRow extends StatelessWidget {
  const _ContactSelectionRow({
    required this.methodKey,
    required this.isSelected,
    required this.onToggle,
    required this.child,
  });

  final String methodKey;
  final bool isSelected;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Local theme override: swap primary with secondary for this row
    final localTheme = theme.copyWith(
      colorScheme: colorScheme.copyWith(primary: colorScheme.secondary),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.input),
          borderSide: BorderSide(
            color: colorScheme.secondary,
            width: 2,
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Theme(
            data: localTheme,
            child: AnimatedOpacity(
              duration: MinglitAnimation.fast,
              opacity: isSelected ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !isSelected,
                child: child,
              ),
            ),
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
              vertical: MinglitSpacing.medium,
            ),
            child: AnimatedSwitcher(
              duration: MinglitAnimation.fast,
              child: isSelected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('checked'),
                      color: colorScheme.secondary,
                      size: MinglitIconSize.large,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      key: const ValueKey('unchecked'),
                      color: colorScheme.outlineVariant,
                      size: MinglitIconSize.large,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
