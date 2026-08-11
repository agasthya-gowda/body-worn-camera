import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A6B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.videocam, size: 60, color: Color(0xFF4A9EFF)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: size.width * 0.8,
              child: const Text(
                'BWC Mobile',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: size.width * 0.8,
              child: const Text(
                'Police Department',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(fontSize: 16, color: Color(0xFF4A9EFF)),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Color(0xFF4A9EFF)),
          ],
        ),
      ),
    );
  }
}
