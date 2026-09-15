import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'screens/splash_screen.dart';
import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Adds RTSP/FFmpeg-backed decoding to video_player - no web implementation
  // exists, so live camera video only plays on Android/iOS/desktop for now.
  if (!kIsWeb) {
    fvp.registerWith();
  }
  await ThemeController.instance.load();
  runApp(const BWCApp());
}

class BWCApp extends StatelessWidget {
  const BWCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTheme(
      controller: ThemeController.instance,
      child: MaterialApp(
        title: 'BWC Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A3A6B),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
