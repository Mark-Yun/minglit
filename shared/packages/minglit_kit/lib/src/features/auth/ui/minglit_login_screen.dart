import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/config/url_config.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// A common login screen for both User and Partner apps.
class MinglitLoginScreen extends ConsumerWidget {
  /// Creates a [MinglitLoginScreen].
  const MinglitLoginScreen({
    super.key,
    this.onGoogleSignIn,
    this.onAppleSignIn,
    this.onKakaoSignIn,
    this.onVerifyIdentity,
    this.isPartner = false,
    this.onDevMapTrigger,
  });

  /// Callback when Google sign-in is pressed.
  final VoidCallback? onGoogleSignIn;

  /// Callback when Apple sign-in is pressed.
  final VoidCallback? onAppleSignIn;

  /// Callback when Kakao sign-in is pressed.
  final VoidCallback? onKakaoSignIn;

  /// Callback when Verify Identity is pressed (User only).
  final VoidCallback? onVerifyIdentity;

  /// Whether this is for the Partner app (theme adjustment).
  final bool isPartner;

  /// Callback to trigger DevMap (hidden gesture). Null in production.
  final VoidCallback? onDevMapTrigger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme colors (User: Navy / Partner: Orange)
    final theme = Theme.of(context);
    final slogan = isPartner
        ? 'Verified Vibe, Spark Your Business'
        : 'Verified Vibe, Spark Your Moment';

    final textStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.outline,
    );
    final linkStyle = textStyle.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.bold,
    );

    final urlConfig = ref.watch(minglitUrlConfigProvider);

    return Scaffold(
      backgroundColor: MinglitColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // 1. Logo & Slogan
              if (onDevMapTrigger != null)
                _DevTriggerLogo(onTrigger: onDevMapTrigger!)
              else
                const MinglitImage(
                  path:
                      'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
                  height: 64,
                ),
              if (isPartner)
                Text(
                  'PARTNER',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                    letterSpacing: 2,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                slogan,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Spacer(),

              // 2. Login Buttons
              _LoginButton(
                onPressed: onGoogleSignIn,
                icon: Icons.g_mobiledata,
                label: 'Google로 시작하기',
                backgroundColor: MinglitColors.background,
                foregroundColor: MinglitColors.textPrimary.withValues(
                  alpha: 0.87,
                ),
                borderColor: theme.colorScheme.outlineVariant,
              ),
              if (onAppleSignIn != null) ...[
                const SizedBox(height: 12),
                _LoginButton(
                  onPressed: onAppleSignIn,
                  icon: Icons.apple,
                  label: 'Apple로 시작하기',
                  backgroundColor: MinglitColors.textPrimary,
                  foregroundColor: MinglitColors.background,
                ),
              ],
              const SizedBox(height: 12),
              _LoginButton(
                onPressed: onKakaoSignIn,
                icon: Icons.chat_bubble,
                label: 'Kakao로 시작하기',
                backgroundColor: MinglitColors.warning,
                foregroundColor: MinglitColors.textPrimary.withValues(
                  alpha: 0.87,
                ),
              ),
              if (!isPartner && onVerifyIdentity != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onVerifyIdentity,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: const Text('본인인증 테스트'),
                ),
              ],
              const SizedBox(height: 12),
              if (isPartner) ...[
                TextButton(
                  onPressed: () => _launchUrl(urlConfig.partnerInquiryUrl),
                  child: const Text('파트너 입점 문의'),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.sm,
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: '로그인 시 ',
                      style: textStyle,
                      children: [
                        TextSpan(
                          text: '이용약관',
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl(urlConfig.termsUrl),
                        ),
                        const TextSpan(text: ' 및 '),
                        TextSpan(
                          text: '개인정보처리방침',
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl(urlConfig.privacyUrl),
                        ),
                        const TextSpan(text: '에 동의하게 됩니다.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DevTriggerLogo extends StatefulWidget {
  const _DevTriggerLogo({required this.onTrigger});

  final VoidCallback onTrigger;

  @override
  State<_DevTriggerLogo> createState() => _DevTriggerLogoState();
}

class _DevTriggerLogoState extends State<_DevTriggerLogo> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    // Reset if more than 2 seconds since last tap.
    if (_lastTap != null && now.difference(_lastTap!).inSeconds >= 2) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      widget.onTrigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: const MinglitImage(
        path: 'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
        height: 64,
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: Icon(icon, size: 20, color: foregroundColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
