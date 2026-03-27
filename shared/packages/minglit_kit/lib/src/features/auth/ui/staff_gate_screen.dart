import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/auth/logic/staff_guard_provider.dart';
import 'package:minglit_kit/src/features/loading/global_loading_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';

/// Displays the staff verification gate UI.
class StaffGateScreen extends ConsumerStatefulWidget {
  /// Creates a staff gate screen.
  const StaffGateScreen({super.key});

  /// Creates the state for the staff gate screen.
  @override
  ConsumerState<StaffGateScreen> createState() => _StaffGateScreenState();
}

class _StaffGateScreenState extends ConsumerState<StaffGateScreen> {
  final _emailController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSendLink() async {
    final email = _emailController.text.trim();
    if (!email.endsWith('@minglit.com')) {
      setState(() => _message = '오직 @minglit.com 이메일만 사용 가능합니다.');
      return;
    }

    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    setState(() => _message = null);

    try {
      await ref.read(staffGuardProvider.notifier).requestMagicLink(email);
      setState(() => _message = '매직 링크가 발송되었습니다. 메일함을 확인해 주세요.');
    } on Object catch (e) {
      setState(() => _message = '발송 실패: $e');
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: MinglitColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Logo Section
                const MinglitImage(
                  path:
                      'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
                  height: 48,
                ),
                const SizedBox(height: MinglitSpacing.xlarge),

                // 2. Header Text
                Text(
                  'Staff Verification',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.small),
                Text(
                  '보안을 위해 @minglit.com 인증이 필요합니다.',
                  textAlign: TextAlign.center,
                  style: MinglitTextStyles.infoText(context),
                ),
                const SizedBox(height: MinglitSpacing.xlarge),

                // 3. Email Input
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Minglit Email',
                    hintText: 'name@minglit.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                  onSubmitted: (_) => _onSendLink(),
                ),
                const SizedBox(height: MinglitSpacing.medium),

                // 4. Feedback Message
                if (_message != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    margin: const EdgeInsets.only(
                      bottom: MinglitSpacing.medium,
                    ),
                    decoration: BoxDecoration(
                      color: _message!.contains('발송되었습니다')
                          ? colorScheme.primaryContainer.withValues(
                              alpha: MinglitOpacity.muted,
                            )
                          : colorScheme.errorContainer.withValues(
                              alpha: MinglitOpacity.muted,
                            ),
                      borderRadius: BorderRadius.circular(MinglitRadius.input),
                    ),
                    child: Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _message!.contains('발송되었습니다')
                            ? colorScheme.primary
                            : colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // 5. Submit Button
                ElevatedButton(
                  onPressed: _onSendLink,
                  child: const Text('인증 링크 발송'),
                ),
                const SizedBox(height: MinglitSpacing.large),

                // 6. Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: MinglitSpacing.xsmall),
                    Text(
                      'Internal Preview Environment',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
