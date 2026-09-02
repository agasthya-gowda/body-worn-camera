import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _introOpacity;
  late final Animation<double> _introScale;
  late final AnimationController _loopController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _introOpacity = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
    );
    _introScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));
    _introController.forward();

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  Widget _bouncingDot(double delayFraction) {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final t = (_loopController.value + delayFraction) % 1.0;
        final bounce = (t < 0.5)
            ? Curves.easeOut.transform(t * 2)
            : Curves.easeIn.transform(1 - (t - 0.5) * 2);
        return Transform.translate(
          offset: Offset(0, -8 * bounce),
          child: child,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF60A5FA),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF10223D),
                  Color(0xFF1A3A6B),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: size.width * 0.85 < 320 ? size.width * 0.85 : 320,
                height: size.width * 0.85 < 320 ? size.width * 0.85 : 320,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _introOpacity,
            child: ScaleTransition(
              scale: _introScale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A3A6B), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.5),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 48,
                            color: Color(0xFF60A5FA),
                          ),
                          const Positioned(
                            bottom: 8,
                            right: 8,
                            child: Icon(
                              Icons.videocam,
                              size: 22,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: AnimatedBuilder(
                              animation: _loopController,
                              builder: (context, child) {
                                final pulse =
                                    (0.5 +
                                            0.5 *
                                                (1 -
                                                    (_loopController.value -
                                                                0.5)
                                                            .abs() *
                                                        2))
                                        .clamp(0.35, 1.0);
                                return Opacity(opacity: pulse, child: child);
                              },
                              child: const Icon(
                                Icons.podcasts,
                                size: 16,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'BWC ',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        TextSpan(
                          text: 'MOBILE',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFF60A5FA),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'BODY WORN CAMERA • TACTICAL EVIDENCE NETWORK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF93C5FD).withOpacity(0.8),
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            child: FadeTransition(
              opacity: _introOpacity,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _bouncingDot(0.0),
                      const SizedBox(width: 6),
                      _bouncingDot(0.15),
                      const SizedBox(width: 6),
                      _bouncingDot(0.3),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CHIPSCAPE SECURITY SYSTEMS',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFBFDBFE).withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
