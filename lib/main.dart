import 'package:ai_wallpaper/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/push_notification_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash screen up until custom splash screen is loaded
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    await dotenv.load(fileName: ".env");

    await PushNotificationService.initialize(); // ✅ only once here
  } catch (e) {
    debugPrint("Initialization failed: $e");
  } finally {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Remove the native splash screen as soon as possible
    FlutterNativeSplash.remove();

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
