import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_identification/minglit_identification.dart';
import 'package:minglit_identification/src/implementation/identification_stub.dart'
    if (dart.library.io) 'package:minglit_identification/src/implementation/identification_io.dart'
    if (dart.library.js_interop) 'package:minglit_identification/src/implementation/identification_web.dart';
import 'package:minglit_kit/src/data/repositories/identity_repository.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/utils/error_ui_handler.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';

/// **Identity Verification Screen**
///
/// A screen where users verify their real identity via Portone (PASS/SMS).
class IdentityVerificationScreen extends ConsumerStatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  bool _isLoading = false;

  Future<void> _startVerification() async {
    setState(() => _isLoading = true);

    try {
      // Unique Merchant UID for this transaction
      final merchantUid = 'IDV_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Open Portone Verification Window
      // Note: IdentificationProviderImpl is exported from minglit_identification
      final provider = IdentificationProviderImpl();
      final verificationId = await provider.verify(
        context: context,
        merchantUid: merchantUid,
      );

      if (verificationId == null) {
        throw const MinglitUserException('본인인증이 취소되었습니다.');
      }

      // 2. Server-side Verification & DB Update
      await ref.read(identityRepositoryProvider).verifyIdentity(
            identityVerificationId: verificationId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 본인인증이 성공적으로 완료되었습니다.')),
        );
        Navigator.of(context).pop(true);
      }
    } on Object catch (e, st) {
      if (mounted) {
        handleMinglitError(context, e, st);
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
              const Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: MinglitSpacing.large),
              Text(
                '안전한 만남을 위해\n본인인증이 필요합니다.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.medium),
              Text(
                '타인의 명의를 도용할 경우\n관련 법령에 따라 처벌받을 수 있습니다.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xlarge * 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startVerification,
                  child: _isLoading
                      ? const MinglitCircularProgressIndicator(size: 20)
                      : const Text('본인인증 시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
