import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// A common login screen for both User and Partner apps.
class MinglitLoginScreen extends StatelessWidget {
  /// Creates a [MinglitLoginScreen].
  const MinglitLoginScreen({
    super.key,
    this.onGoogleSignIn,
    this.onKakaoSignIn,
    this.isPartner = false,
  });

  /// Callback when Google sign-in is pressed.
  final VoidCallback? onGoogleSignIn;

  /// Callback when Kakao sign-in is pressed.
  final VoidCallback? onKakaoSignIn;

  /// Whether this is for the Partner app (theme adjustment).
  final bool isPartner;

  @override
  Widget build(BuildContext context) {
    // Theme colors (User: Navy / Partner: Orange)
    final slogan = isPartner
        ? 'Verified Vibe, Spark Your Business'
        : 'Verified Vibe, Spark Your Moment';

    final textStyle = TextStyle(color: Colors.grey[500], fontSize: 12);
    final linkStyle = textStyle.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // 1. Logo & Slogan
              const MinglitImage(
                path:
                    'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
                height: 64,
              ),
              if (isPartner)
                const Text(
                  'PARTNER',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 2,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                slogan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),

              // 2. Login Buttons
              OutlinedButton.icon(
                onPressed: onGoogleSignIn,
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Google로 시작하기'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onKakaoSignIn,
                icon: const Icon(Icons.chat_bubble, size: 18),
                label: const Text('Kakao로 시작하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (isPartner) ...[
                TextButton(
                  onPressed: () => _launchUrl('https://partner.minglit.com'),
                  child: const Text('파트너 입점 문의'),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text.rich(
                    TextSpan(
                      text: '로그인 시 ',
                      style: textStyle,
                      children: [
                        TextSpan(
                          text: '이용약관',
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                _launchUrl('https://minglit.com/terms'),
                        ),
                        const TextSpan(text: ' 및 '),
                        TextSpan(
                          text: '개인정보처리방침',
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                _launchUrl('https://minglit.com/privacy'),
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
