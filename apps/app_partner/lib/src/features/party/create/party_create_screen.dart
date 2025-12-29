import 'dart:io';

import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  final Set<String> _selectedVerificationIds = {};

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

    final min = int.tryParse(_minCountController.text) ?? 0;
    final max = int.tryParse(_maxCountController.text) ?? 0;

    if (min > max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 인원은 최소 인원보다 커야 합니다.')),
      );
      return;
    }

    if (_quillController.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파티 설명을 입력해주세요.')),
      );
      return;
    }

    final descriptionJson = {
      'ops': _quillController.document.toDelta().toJson(),
    };

    final coordinator = PartyCreateCoordinator(context);

    try {
      await ref
          .read(partyCreateControllerProvider.notifier)
          .createParty(
            title: _titleController.text,
            description: descriptionJson,
            minConfirmedCount: min,
            maxParticipants: max,
            contactPhone: _phoneController.text,
            contactEmail: _emailController.text,
            contactKakao: _kakaoController.text.isNotEmpty
                ? _kakaoController.text
                : null,
            requiredVerificationIds: _selectedVerificationIds.toList(),
            imageFile: _selectedImage,
          );

      final state = ref.read(partyCreateControllerProvider);
      if (state.hasError) {
        coordinator.onError(state.error!);
              } else {
              coordinator.onPartyCreated();
            }
          } on Exception catch (e) {
            coordinator.onError(e);
          }
        }
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partyCreateControllerProvider);
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

    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('파티 기획하기'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submit,
            child: const Text(
              '등록',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 파티 제목
              const _SectionTitle('파티 제목'),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '예: 강남역 불금 와인 파티',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (v) => v?.isEmpty ?? false ? '파티 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 24),

              // 2. 파티 설명
              const _SectionTitle('상세 설명'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController,
                      config: const quill.QuillSimpleToolbarConfig(
                        showFontFamily: false,
                        showFontSize: false,
                        showSearchButton: false,
                        showInlineCode: false,
                        showSubscript: false,
                        showSuperscript: false,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 250,
                      child: quill.QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _editorFocusNode,
                        config: const quill.QuillEditorConfig(
                          placeholder: '파티의 분위기, 제공되는 음식, 음악 등을 자유롭게 꾸며보세요!',
                          padding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. 대표 이미지
              const _SectionTitle('대표 이미지'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
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
                              color: Colors.orange[300],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '터치하여 커버 이미지를 등록하세요',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

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
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? false ? '필수' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '최대 정원',
                        suffixText: '명',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? false ? '필수' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. 문의 연락처 (Auto-filled)
              const _SectionTitle('문의 연락처'),
              if (partnerInfoAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    '파트너 정보 불러오는 중...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, size: 18),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, size: 18),
                ),
              ),
              const SizedBox(height: 16),

              // Kakao Link
              TextFormField(
                controller: _kakaoController,
                decoration: const InputDecoration(
                  labelText: '오픈카카오톡 링크 (선택)',
                  hintText: 'https://open.kakao.com/o/...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.chat_bubble_outline, size: 18),
                  helperText: '참가자들과 소통할 오픈채팅방 링크를 입력해주세요.',
                ),
              ),
              const SizedBox(height: 24),

              // 6. 참가 자격
              const _SectionTitle('참가 자격 (인증)'),
              verificationsAsync.when(
                data: (verifications) => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: verifications.map((v) {
                    final id = v['id'] as String;
                    final name = v['title'] as String;
                    final isSelected = _selectedVerificationIds.contains(id);
                    return FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedVerificationIds.add(id);
                          } else {
                            _selectedVerificationIds.remove(id);
                          }
                        });
                      },
                      checkmarkColor: Colors.white,
                      selectedColor: const Color(0xFFFF7043),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('인증 목록 로드 실패: $e'),
              ),

              const SizedBox(height: 50),

              // 하단 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF1A237E), // Navy Button
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '파티 생성 완료',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E), // Midnight Navy
        ),
      ),
    );
  }
}
