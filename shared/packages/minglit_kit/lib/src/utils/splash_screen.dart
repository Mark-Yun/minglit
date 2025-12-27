import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A branded splash screen shown during app initialization.
class MinglitSplashScreen extends StatelessWidget {
  /// Creates a [MinglitSplashScreen].
  const MinglitSplashScreen({
    required this.appName,
    super.key,
    this.isPartner = false,
  });

  /// The name of the specific application.
  final String appName;

  /// Whether this is for the Partner app.
  final bool isPartner;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isPartner ? const Color(0xFFFF7043) : const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Minglit',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appName.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
