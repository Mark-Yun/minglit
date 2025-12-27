import 'package:app_user/src/features/verification/career_verification_form.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

/// 다중 인증 및 보완 요청 관리 페이지
class VerificationManagementPage extends StatefulWidget {
  const VerificationManagementPage({
    required this.partnerId,
    required this.requiredVerificationIds,
    super.key,
  });
  final String partnerId;
  final List<String> requiredVerificationIds;

  @override
  State<VerificationManagementPage> createState() =>
      _VerificationManagementPageState();
}

class _VerificationManagementPageState
    extends State<VerificationManagementPage> {
  final ImagePicker _imagePicker = ImagePicker();

  // 각 인증 항목별 현재 입력 데이터 및 파일 관리
  final _draftData = <String, Map<String, dynamic>>{};
  final _draftFiles = <String, XFile?>{};

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() {
    context.read<VerificationBloc>().add(
      VerificationEvent.loadPartnerRequirements(
        partnerId: widget.partnerId,
        requiredIds: widget.requiredVerificationIds,
      ),
    );
  }

  Future<void> _pickImage(String vId) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _draftFiles[vId] = image);
    }
  }

  void _submitAll(List<VerificationRequirementStatus> requirements) {
    for (final req in requirements) {
      final vId = req.master['id'] as String;
      if (_draftData.containsKey(vId) || _draftFiles[vId] != null) {
        final files =
            _draftFiles[vId] != null ? [_draftFiles[vId]!] : <XFile>[];

        context.read<VerificationBloc>().add(
          VerificationEvent.submitVerification(
            partnerId: widget.partnerId,
            verificationId: vId,
            claimData:
                (_draftData[vId] ??
                        req.originalData?['claim_data'] ??
                        <String, dynamic>{})
                    as Map<String, dynamic>,
            proofFiles: files,
            existingRequestId: req.activeRequest?['id'] as String?,
          ),
        );
      }
    }
  }

  Future<void> _showCommentsModal(String requestId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsModal(requestId: requestId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        state.whenOrNull(
          success: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('모든 수정사항이 제출되었습니다.')));
            _refreshStatus(); // 제출 성공 후 상태 새로고침
          },
          failure: (msg) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('제출 실패: $msg')));
          },
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('파티 참가 인증')),
          body: state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            requirementsLoaded: (requirements) {
              final completedCount =
                  requirements.where((r) => r.isApproved).length;
              final totalCount = requirements.length;

              return Column(
                children: [
                  _buildSummaryHeader(completedCount, totalCount),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requirements.length,
                      itemBuilder:
                          (context, index) =>
                              _buildVerificationCard(requirements[index]),
                    ),
                  ),
                  _buildSubmitButton(requirements),
                ],
              );
            },
            orElse: () => const Center(child: Text('인증 정보를 불러오는 중입니다...')),
          ),
        );
      },
    );
  }

  Widget _buildSummaryHeader(int completed, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인증 현황 ($completed/$total)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            completed == total
                ? '모든 인증이 완료되었습니다! 파티에 참가하세요.'
                : '필요한 인증 항목을 작성해 주세요.',
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(VerificationRequirementStatus req) {
    final vId = req.master['id'] as String;
    final isApproved = req.isApproved;
    final needsCorrection = req.status == VerificationStatus.needsCorrection;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              needsCorrection
                  ? Colors.red
                  : (isApproved ? Colors.green : Colors.grey[300]!),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: needsCorrection,
        leading: Icon(
          isApproved
              ? Icons.check_circle
              : (needsCorrection ? Icons.error : Icons.add_circle_outline),
          color:
              isApproved
                  ? Colors.green
                  : (needsCorrection ? Colors.red : Colors.grey),
        ),
        title: Text(
          req.master['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isApproved ? '인증 완료' : (needsCorrection ? '보완 요청됨' : '정보 입력 필요'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (needsCorrection) _buildCorrectionBanner(req),
                const SizedBox(height: 16),
                _buildFormByCategory(req),
                const SizedBox(height: 24),
                const Text(
                  '증빙 서류',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildImagePicker(vId, req),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionBanner(VerificationRequirementStatus req) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '심사관 의견',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            req.activeRequest?['rejection_reason'] as String? ??
                '서류를 다시 확인해 주세요.',
          ),
          TextButton(
            onPressed:
                () async =>
                    _showCommentsModal(req.activeRequest!['id'] as String),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: const Text('대화 내역 보기 >'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormByCategory(VerificationRequirementStatus req) {
    final vId = req.master['id'] as String;
    final category = VerificationCategory.values.byName(
      req.master['category'] as String,
    );
    final initialData =
        (req.activeRequest?['claim_snapshot'] ??
                req.originalData?['claim_data'])
            as Map<String, dynamic>?;

    switch (category) {
      case VerificationCategory.career:
        return CareerVerificationForm(
          initialData: initialData,
          onChanged: (data) => _draftData[vId] = data,
        );
      case VerificationCategory.asset:
      case VerificationCategory.marriage:
      case VerificationCategory.academic:
      case VerificationCategory.vehicle:
      case VerificationCategory.etc:
        return const Text('이 카테고리의 폼은 아직 준비 중입니다.');
    }
  }

  Widget _buildImagePicker(String vId, VerificationRequirementStatus req) {
    final hasNewFile = _draftFiles[vId] != null;
    final hasOriginalFile =
        (req.originalData?['proof_images'] as List?)?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: () async => _pickImage(vId),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child:
            hasNewFile
                ? Image.network(_draftFiles[vId]!.path, fit: BoxFit.contain)
                : hasOriginalFile
                ? const Center(
                  child: Text(
                    '기존 서류 있음 (클릭하여 교체)',
                    style: TextStyle(color: Colors.blue),
                  ),
                )
                : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.grey),
                    Text(
                      '사진 선택',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSubmitButton(List<VerificationRequirementStatus> requirements) {
    final hasChanges = _draftData.isNotEmpty || _draftFiles.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: hasChanges ? () => _submitAll(requirements) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '수정 및 제출하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentsModal extends StatefulWidget {
  const _CommentsModal({required this.requestId});
  final String requestId;

  @override
  State<_CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<_CommentsModal> {
  @override
  void initState() {
    super.initState();
    context.read<VerificationBloc>().add(
      VerificationEvent.loadComments(requestId: widget.requestId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '심사 대화 내역',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: BlocBuilder<VerificationBloc, VerificationState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  commentsLoaded: (List<Map<String, dynamic>> comments) {
                    if (comments.isEmpty) {
                      return const Center(child: Text('대화 내역이 없습니다.'));
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final content =
                            comment['content'] as Map<String, dynamic>;
                        final isMe =
                            comment['author_id'] ==
                            Supabase.instance.client.auth.currentUser?.id;

                        return Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(content['text'] as String? ?? ''),
                          ),
                        );
                      },
                    );
                  },
                  failure: (msg) => Center(child: Text('Error: $msg')),
                  orElse: () => const Center(child: Text('불러오는 중...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
