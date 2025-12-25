import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinglitSplashScreen extends StatelessWidget {
  final String appName;
  final bool isPartner;

  const MinglitSplashScreen({
    super.key,
    required this.appName,
    this.isPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isPartner ? const Color(0xFFFF7043) : const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 텍스트 (나중에 이미지 로고로 교체 가능)
            Text(
              'Minglit',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            if (isPartner) ...[
              const SizedBox(height: 8),
              Text(
                'PARTNER',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 4.0,
                ),
              ),
            ],
            const SizedBox(height: 48),
            // 로딩 인디케이터
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
