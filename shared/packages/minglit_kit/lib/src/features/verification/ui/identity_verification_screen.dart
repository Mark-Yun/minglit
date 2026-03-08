import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:minglit_iamport_v1/minglit_iamport_v1.dart';
import 'package:minglit_kit/src/config/iamport_config.dart';
import 'package:minglit_kit/src/data/repositories/identity_repository.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/utils/error_ui_handler.dart';

/// **Identity Verification Screen**
///
/// A screen where users verify their real identity via Iamport (V1).
class IdentityVerificationScreen extends ConsumerStatefulWidget {
  /// Creates an identity verification screen.
  const IdentityVerificationScreen({super.key});

  /// Creates the state for the identity verification screen.
  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  bool _isLoading = true; // Start with loading state
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-start verification after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startVerification());
    });
  }

  Future<void> _startVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final merchantUid = 'IDV_${DateTime.now().millisecondsSinceEpoch}';
      final config = ref.read(iamportConfigProvider);

      final service = getCertificationService();
      final verificationId = await service.verify(
        context: context,
        userCode: config.userCode,
        merchantUid: merchantUid,
        mRedirectUrl: config.mobileRedirectUrl,
      );

      if (verificationId == null) {
        // User cancelled or window blocked
        setState(() {
          _errorMessage = '인증이 취소되었거나 창이 열리지 않았습니다.';
        });
        return;
      }

      await ref
          .read(identityRepositoryProvider)
          .verifyIdentity(
            identityVerificationId: verificationId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 본인인증이 성공적으로 완료되었습니다.')),
        );
        Navigator.of(context).pop(true);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '인증 중 오류가 발생했습니다.');
        handleMinglitError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '본인인증'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const MinglitCircularProgressIndicator(size: 48),
                const SizedBox(height: MinglitSpacing.xlarge),
                Text(
                  '본인인증 창을 불러오는 중입니다...',
                  style: theme.textTheme.titleMedium,
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: MinglitColors.warning,
                ),
                const SizedBox(height: MinglitSpacing.large),
                Text(
                  _errorMessage ?? '인증을 진행해주세요.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: MinglitSpacing.xlarge),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _startVerification,
                    child: const Text('본인인증 다시 시도하기'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
