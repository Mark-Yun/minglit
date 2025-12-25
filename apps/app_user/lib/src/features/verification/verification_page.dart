import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class VerificationPage extends StatefulWidget {
  final VerificationCategory category;
  // 초기 데이터를 받을 수 있도록 빌더 형태로 변경
  final Widget Function(Map<String, dynamic>? initialData) formBuilder;
  final Map<String, dynamic> Function() onGetData;

  const VerificationPage({
    super.key,
    required this.category,
    required this.formBuilder,
    required this.onGetData,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();

  // 상태 관리
  bool _isLoading = true;
  Map<String, dynamic>? _activeRequest;
  bool _isEditingRejected = false; // 반려된 건을 수정 중인지 여부

  // 입력 폼 상태 (웹 호환을 위해 XFile 사용)
  XFile? _proofFile;
  bool _isPdf = false;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _checkActiveRequest();
  }

  String _getCategoryTitle() {
    switch (widget.category) {
      case VerificationCategory.career:
        return '직장 인증';
      case VerificationCategory.asset:
        return '자산 인증';
      case VerificationCategory.marriage:
        return '혼인 인증';
      case VerificationCategory.academic:
        return '학력 인증';
      case VerificationCategory.vehicle:
        return '차량 인증';
      case VerificationCategory.etc:
        return '기타 인증';
    }
  }

  Future<void> _checkActiveRequest() async {
    try {
      final service = locator<VerificationService>();
      final request = await service.getActiveRequest(widget.category);
      if (mounted) {
        setState(() {
          _activeRequest = request;
          _isLoading = false;
          _isEditingRejected = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      Log.e('Check active request error', e);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('사진 촬영'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('문서 선택 (PDF)'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickDocument();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );

    if (image != null) {
      setState(() {
        _proofFile = image;
        _isPdf = false;
        _fileName = image.name;
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      final platformFile = result.files.single;
      if (platformFile.size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일 크기는 10MB를 초과할 수 없습니다.')),
          );
        }
        return;
      }

      setState(() {
        _proofFile = XFile.fromData(
          platformFile.bytes!,
          name: platformFile.name,
          path: platformFile.path,
        );
        _isPdf = true;
        _fileName = platformFile.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_proofFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('증빙 서류를 업로드해주세요.')));
      return;
    }

    Log.d('🚀 Submitting verification request...');
    setState(() => _isLoading = true);
    try {
      final claimData = widget.onGetData();
      final service = locator<VerificationService>();

      // 기존 반려된 요청이 있다면 취소(삭제)하고 새로 제출 (간단한 구현 위해)
      if (_activeRequest != null && _activeRequest!['status'] == 'rejected') {
        Log.d('🗑️ Removing previous rejected request...');
        await service.cancelRequest(_activeRequest!['id']);
      }

      await service.submitRequest(
        category: widget.category,
        claimData: claimData,
        proofFiles: [_proofFile!],
      );

      await _checkActiveRequest();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('인증 요청이 제출되었습니다.')));
      }
    } catch (e, stackTrace) {
      Log.e('❌ Submission Error in UI', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('제출 실패: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRequest() async {
    if (_activeRequest == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('요청 취소'),
            content: const Text('인증 요청을 취소하시겠습니까?\n제출된 정보와 파일은 즉시 삭제됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('아니오'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  '네, 취소합니다',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final service = locator<VerificationService>();
      await service.cancelRequest(_activeRequest!['id']);

      if (mounted) {
        setState(() {
          _activeRequest = null;
          _proofFile = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('요청이 취소되었습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('취소 실패: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getCategoryTitle())),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_activeRequest != null && !_isEditingRejected)
              ? _buildStatusView()
              : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    // 반려된 건 수정 중이라면 기존 데이터 추출
    final initialData =
        _isEditingRejected
            ? _activeRequest!['claim_data'] as Map<String, dynamic>?
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리별 폼 (초기값 전달)
          widget.formBuilder(initialData),
          const SizedBox(height: 32),

          const Text(
            '증빙 서류 업로드',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '명함, 사원증, 재직증명서(PDF) 등을 업로드해주세요.\n개인정보는 심사 후 안전하게 관리됩니다.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showPickerOptions,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child:
                  _proofFile != null
                      ? _buildPreview()
                      : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            '사진 또는 PDF 선택',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
            ),
          ),
          if (_proofFile != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed:
                    () => setState(() {
                      _proofFile = null;
                      _isPdf = false;
                      _fileName = null;
                    }),
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                label: const Text('파일 삭제', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
          const SizedBox(height: 48),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditingRejected ? '수정 후 재신청' : '인증 신청하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_isEditingRejected)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isEditingRejected = false),
                child: const Text('취소하고 상태 보기'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusView() {
    final status = _activeRequest!['status'];
    final bool isApproved = status == 'approved';
    final bool isRejected = status == 'rejected';
    final claimData = _activeRequest!['claim_data'] as Map<String, dynamic>?;
    final rejectionReason = _activeRequest!['rejection_reason'] as String?;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApproved
                  ? Icons.check_circle
                  : (isRejected ? Icons.error : Icons.hourglass_top),
              size: 80,
              color:
                  isApproved
                      ? Colors.green
                      : (isRejected ? Colors.red : Colors.orange),
            ),
            const SizedBox(height: 24),
            Text(
              isApproved ? '인증 완료!' : (isRejected ? '인증 반려' : '심사 중입니다'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '반려 사유',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rejectionReason ?? '사유가 입력되지 않았습니다.',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isEditingRejected = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('수정 후 재신청'),
                ),
              ),
            ] else if (!isApproved) ...[
              const Text(
                '제출하신 서류를 꼼꼼히 확인하고 있습니다.\n보통 1~2일 내에 처리가 완료됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 32),

            if (claimData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children:
                      claimData.entries
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    e.value.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],

            if (!isApproved && !isRejected) ...[
              const SizedBox(height: 48),
              OutlinedButton.icon(
                onPressed: _cancelRequest,
                icon: const Icon(Icons.close),
                label: const Text('요청 취소하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isPdf) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            _fileName ?? 'PDF Document',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return Container(
        color: Colors.black.withOpacity(0.05),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _proofFile!.path,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }
  }
}
