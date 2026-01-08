  import 'package:flutter/material.dart';
  import 'package:camera/camera.dart';
  import 'screens/splash_screen.dart';
  import 'core/supabase_config.dart';

  /// Global camera list (aman walau kosong)
  List<CameraDescription> cameras = [];

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1️⃣ Init Supabase (WAJIB sebelum runApp)
    try {
      await SupabaseConfig.initialize();
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }

    // 2️⃣ Init Camera
    try {
      cameras = await availableCameras();
    } catch (e) {
      debugPrint("Kamera tidak ditemukan: $e");
    }

    // 3️⃣ Run App
    runApp(const MyApp());
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Absenku',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A7DFF),
          ),
        ),
        home: const SplashScreen(),
      );
    }
  }

