import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:minglit_iamport_v1/minglit_iamport_v1.dart';
import 'package:minglit_kit/src/config/iamport_config.dart';
import 'package:minglit_kit/src/data/models/user_consent.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/consent_repository.dart';
import 'package:minglit_kit/src/features/consent/logic/consent_controller.dart';
import 'package:minglit_kit/src/features/iamport/data/repository/iamport_repository.dart';
import 'package:minglit_kit/src/features/verification/ui/identity_verification_consent_sheet.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/utils/error_ui_handler.dart';

/// **Identity Verification Screen**
///
/// A screen where users verify their real identity via Iamport (V2).
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
      unawaited(_startVerificationFlow());
    });
  }

  Future<void> _startVerificationFlow() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasConsent = await _ensureIdentityVerificationConsent();
      if (!hasConsent) return;

      await _startVerification();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '인증 중 오류가 발생했습니다.');
        handleMinglitError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensureIdentityVerificationConsent() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _errorMessage = '로그인이 필요합니다.';
      return false;
    }

    final consents = await ref
        .read(consentRepositoryProvider)
        .getConsents(
          user.id,
        );
    final hasConsent = consents.any(
      (consent) => consent.consentKey == ConsentType.identityVerification,
    );
    if (hasConsent) return true;

    if (!mounted) return false;

    final agreed = await showIdentityVerificationConsentSheet(context);
    if (!agreed) {
      _errorMessage = '본인확인정보 수집·이용 동의 후 인증을 진행할 수 있습니다.';
      return false;
    }

    await ref
        .read(consentControllerProvider.notifier)
        .toggleConsent(ConsentType.identityVerification, consented: true);

    return true;
  }

  Future<void> _startVerification() async {
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
        .read(iamportRepositoryProvider)
        .verifyCertification(verificationId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 본인인증이 성공적으로 완료되었습니다.')),
      );
      Navigator.of(context).pop(true);
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
                    onPressed: _startVerificationFlow,
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
