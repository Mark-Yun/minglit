import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Reusable Minglit text logo with Racing Sans One + glitch shadows.
class MinglitTextLogo extends StatelessWidget {
  /// Creates a [MinglitTextLogo].
  const MinglitTextLogo({
    super.key,
    this.fontSize = 48,
    this.color = MinglitColors.primary,
    this.showShadows = true,
  });

  /// Font size of the logo text.
  final double fontSize;

  /// Main text color.
  final Color color;

  /// Whether to show the glitch shadow layers.
  final bool showShadows;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Minglit',
      style: TextStyle(
        fontFamily: 'RacingSansOne',
        package: 'minglit_kit',
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 1,
        shadows: showShadows
            ? const [
                Shadow(
                  offset: Offset(2, 2),
                  // Fix #596: hardcoded color → design token
                  color: MinglitColors.glitchCyan,
                ),
                Shadow(offset: Offset(3, 3), color: MinglitColors.secondary),
              ]
            : null,
      ),
    );
  }
}

/// A branded splash screen with two-phase reveal animation.
///
/// **Phase 1** — Gradient background + floating orbs (no text).
/// **Phase 2** — Orbs expand to fill white + colored logo fades in.
class MinglitSplashScreen extends StatefulWidget {
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
  State<MinglitSplashScreen> createState() => _MinglitSplashScreenState();
}

class _MinglitSplashScreenState extends State<MinglitSplashScreen>
    with TickerProviderStateMixin {
  // Continuous orbit for floating orbs.
  late final AnimationController _orbCtrl;

  // Drives the Phase 2 reveal (orb expand + white-out + logo).
  late final AnimationController _revealCtrl;

  // Staggered sub-animations on _revealCtrl.
  late final Animation<double> _orbExpand;
  late final Animation<double> _whiteOverlay;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    unawaited(_orbCtrl.repeat());

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _orbExpand = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0, 0.7, curve: Curves.easeInOut),
    );
    _whiteOverlay = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.1, 0.8, curve: Curves.easeIn),
    );
    _logoFade = CurvedAnimation(
      parent: _revealCtrl,
      curve: const Interval(0.5, 1, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _revealCtrl,
        curve: const Interval(0.5, 1, curve: Curves.easeOutBack),
      ),
    );

    // Phase 1 plays for 1.5 s, then Phase 2 reveal begins.
    unawaited(
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) unawaited(_revealCtrl.forward());
      }),
    );
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_orbCtrl, _revealCtrl]),
        builder: (context, _) {
          final t = _orbCtrl.value;
          final expand = _orbExpand.value;
          final white = _whiteOverlay.value;
          final logoAlpha = _logoFade.value;
          final logoS = _logoScale.value;

          return Stack(
            children: [
              // 1. Gradient background — fades out during reveal.
              Positioned.fill(
                child: Opacity(
                  opacity: (1 - white).clamp(0, 1).toDouble(),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MinglitColors.primary,
                          // Fix #596: hardcoded color → design token
                          MinglitColors.primaryDark,
                          MinglitColors.secondary,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Floating orbs — expand & brighten during reveal.
              _Orb(
                expand: expand,
                top: -20 + math.sin(t * 2 * math.pi) * 40,
                right: -20 + math.cos(t * 2 * math.pi) * 50,
                baseSize: 320,
                color: Colors.white,
                baseOpacity: 0.12 + math.sin(t * 2 * math.pi) * 0.06,
              ),
              _Orb(
                expand: expand,
                bottom: -10 + math.cos(t * 2 * math.pi + 1) * 35,
                left: -30 + math.sin(t * 2 * math.pi + 1) * 45,
                baseSize: 260,
                color: Colors.white,
                baseOpacity: 0.1 + math.cos(t * 2 * math.pi) * 0.05,
              ),
              _Orb(
                expand: expand,
                top: screenHeight * 0.3 + math.sin(t * 2 * math.pi + 2.5) * 30,
                right: -40 + math.cos(t * 2 * math.pi + 2.5) * 40,
                baseSize: 200,
                color: MinglitColors.tertiary,
                baseOpacity: 0.25 + math.sin(t * 2 * math.pi + 1) * 0.08,
              ),
              _Orb(
                expand: expand,
                top: screenHeight * 0.6 + math.cos(t * 2 * math.pi + 4) * 20,
                left: 40 + math.sin(t * 2 * math.pi + 4) * 30,
                baseSize: 150,
                color: Colors.white,
                baseOpacity: 0.08 + math.cos(t * 2 * math.pi + 3) * 0.04,
              ),

              // 3. White overlay — fades in to white-out.
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: white),
                  ),
                ),
              ),

              // 4. Colored logo — appears during latter half of reveal.
              if (logoAlpha > 0)
                Center(
                  child: Opacity(
                    opacity: logoAlpha,
                    child: Transform.scale(
                      scale: logoS,
                      child: const MinglitTextLogo(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Transition widget for splash → app crossfade with scale pop.
///
/// ```dart
/// AnimatedSwitcher(
///   transitionBuilder: MinglitSplashTransition.build,
///   ...
/// )
/// ```
class MinglitSplashTransition {
  /// Builds a scale+fade transition with a pop effect.
  static Widget build(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    );
  }
}

/// A single floating orb that expands during the reveal phase.
class _Orb extends StatelessWidget {
  const _Orb({
    required this.expand,
    required this.baseSize,
    required this.color,
    required this.baseOpacity,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final double expand;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double baseSize;
  final Color color;
  final double baseOpacity;

  @override
  Widget build(BuildContext context) {
    // During reveal: orbs grow 2.5× and shift towards white.
    final size = baseSize * (1 + expand * 2.5);
    final opacity = (baseOpacity + expand * (0.6 - baseOpacity)).clamp(0, 1);
    final orbColor = Color.lerp(color, Colors.white, expand) ?? Colors.white;

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              orbColor.withValues(alpha: opacity.toDouble()),
              orbColor.withValues(alpha: MinglitOpacity.none),
            ],
          ),
        ),
      ),
    );
  }
}
