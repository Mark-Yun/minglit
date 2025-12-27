import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final primaryColor =
        isPartner ? const Color(0xFFFF7043) : const Color(0xFF1A237E);
    final slogan =
        isPartner
            ? 'Verified Vibe, Spark Your Business'
            : 'Verified Vibe, Spark Your Moment';

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
              Text(
                'Minglit',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              if (isPartner)
                Text(
                  'PARTNER',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 2,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                slogan,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),

              // 2. Login Buttons
              _SocialLoginButton(
                text: 'Google로 시작하기',
                color: Colors.white,
                textColor: Colors.black87,
                icon: Icons.g_mobiledata, // exchange with SVG later
                onPressed: onGoogleSignIn,
                borderColor: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              _SocialLoginButton(
                text: 'Kakao로 시작하기',
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                icon: Icons.chat_bubble, // exchange with SVG later
                onPressed: onKakaoSignIn,
              ),
              const SizedBox(height: 12),
              if (isPartner) ...[
                TextButton(
                  onPressed: () {},
                  child: const Text('파트너 입점 문의'),
                ),
              ] else ...[
                TextButton(
                  onPressed: () {}, // TODO(mark): Terms of service
                  child: Text(
                    '로그인 시 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.icon,
    this.onPressed,
    this.borderColor,
  });

  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side:
                borderColor != null
                    ? BorderSide(color: borderColor!)
                    : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
