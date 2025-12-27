import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinglitLoginScreen extends StatelessWidget {
  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onKakaoSignIn;
  final bool isPartner; // 파트너 앱인지 여부 (테마 색상 변경용)

  const MinglitLoginScreen({
    super.key,
    this.onGoogleSignIn,
    this.onKakaoSignIn,
    this.isPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    // 테마 색상 결정 (User: Navy / Partner: Orange)
    final primaryColor = isPartner ? const Color(0xFFFF7043) : const Color(0xFF1A237E);
    final slogan = isPartner 
        ? 'Verified Vibe, Spark Your Business' 
        : 'Verified Vibe, Spark Your Moment';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                    letterSpacing: 2.0,
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
                icon: Icons.g_mobiledata, // 나중에 SVG 로고로 교체
                onPressed: onGoogleSignIn,
                borderColor: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              _SocialLoginButton(
                text: 'Kakao로 시작하기',
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                icon: Icons.chat_bubble, // 나중에 SVG 로고로 교체
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
                  onPressed: () {}, // TODO: 이용약관 보기
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
  final String text;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? borderColor;

  const _SocialLoginButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.icon,
    this.onPressed,
    this.borderColor,
  });

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
            side: borderColor != null 
                ? BorderSide(color: borderColor!) 
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
