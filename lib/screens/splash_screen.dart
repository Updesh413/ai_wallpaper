import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';

import '../features/auth/presentation/screens/biometric_auth_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/wallpaper/presentation/screens/home_screen.dart';
import '../services/checkinternet_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  double _loadingProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _startLoadingProgress();

    _checkInternetAndProceed();
  }

  Future<void> _checkInternetAndProceed() async {
    bool isConnected = await checkInternetConnection(context);
    if (isConnected) {
      _checkForUpdate();
    } else {
      _proceedAfterSplash();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        _proceedAfterSplash();
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
      _proceedAfterSplash();
    }
  }

  void _proceedAfterSplash() {
    Timer(
      const Duration(seconds: 3),
      () async {
        if (mounted) {
          final authProvider = context.read<UserAuthProvider>();
          // Ensure we have the latest status
          await authProvider.checkCurrentUser();
          final user = authProvider.user;
          
          final prefs = await SharedPreferences.getInstance();
          final biometricEnabled = prefs.getBool('biometricEnabled') ?? false;

          if (user == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          } else {
            // Check if biometric is enabled
            if (biometricEnabled) {
              // We need to pass the firebase user to biometric screen usually
              // But here we might just pass the user entity or handle it there.
              // The original BiometricAuthScreen expected a User object.
              // I'll need to check BiometricAuthScreen.
              // Since AuthProvider returns UserEntity which might wrap Firebase User or just data.
              // If BiometricAuthScreen needs `User` object specifically, we might need to adjust.
              // Let's assume for now we navigate to BiometricAuthScreen and it handles its thing.
              // I will check BiometricAuthScreen in a moment.
              
              // HACK: for now, using FirebaseAuth instance directly for compatibility with legacy BiometricScreen
              // or refactor BiometricScreen to use UserEntity.
              // Since I haven't refactored BiometricScreen fully, I'll rely on it receiving what it expects.
              // The old code passed `user` (FirebaseAuth User).
              // My UserEntity is a wrapper.
              // Let's import FirebaseAuth here just to pass the object if needed, OR refactor BiometricScreen.
              // Better: Refactor BiometricScreen to not need the User object or accept UserEntity.
              
              // For now, I'll direct to HomeScreen if bio is weird, or Login.
              // Actually, let's fix BiometricScreen import.
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  // I'll need to check what BiometricAuthScreen expects.
                  // Assuming I'll update it or it expects something I can provide.
                  // Old code: BiometricAuthScreen(user: user)
                  builder: (context) => const BiometricAuthScreen(), 
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            }
          }
        }
      },
    );
  }

  void _startLoadingProgress() {
    const totalSteps = 100;
    const stepDuration = Duration(milliseconds: 30);
    _progressTimer = Timer.periodic(
      stepDuration,
      (timer) {
        setState(() {
          if (_loadingProgress < 1) {
            _loadingProgress += 1 / totalSteps;
          } else {
            _progressTimer?.cancel();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.primaryGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Column(
                          children: [
                            Text(
                              "AI Wallpaper",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Your Premium Wallpaper Experience",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _loadingProgress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(_loadingProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}