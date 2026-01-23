import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/wallpaper/presentation/providers/wallpaper_provider.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    await Firebase.initializeApp();
    await dotenv.load(fileName: ".env");
    await di.init(); // Initialize dependency injection
    await PushNotificationService.initialize();
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
    FlutterNativeSplash.remove();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<UserAuthProvider>()..checkCurrentUser()),
        ChangeNotifierProvider(create: (_) => di.sl<WallpaperProvider>()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}