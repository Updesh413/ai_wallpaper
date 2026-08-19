import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../../features/wallpaper/presentation/screens/home_screen.dart';
import 'login_screen.dart';
import '../providers/auth_provider.dart';
import '../../../../widgets/glass/glass_background.dart';
import '../../../../widgets/glass/glass_container.dart';
import '../../../../widgets/glass/glass_button.dart';
import '../../../../services/favorites_service.dart';
import '../../../../theme/app_theme.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access AI Wallpaper',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
        if (mounted) {
          context.read<FavoritesService>().initForCurrentUser();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, a1, a2) => const HomeScreen(),
              transitionsBuilder: (context, a1, a2, child) =>
                  FadeTransition(opacity: a1, child: child),
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        }
      } else {
        if (mounted) _handleAuthFailure();
      }
    } catch (e) {
      debugPrint("Biometric authentication error: $e");
      if (mounted) _handleAuthFailure();
    }
    if (mounted) setState(() => _isAuthenticating = false);
  }

  void _handleAuthFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Authentication required. Please sign in.'),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
      ),
    );
    context.read<UserAuthProvider>().signOut();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const LoginScreen(),
        transitionsBuilder: (context, a1, a2, child) =>
            FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassBackground(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: GlassContainer(
              blur: 24,
              borderRadius: 28,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: GlassContainer(
                      padding: EdgeInsets.zero,
                      borderRadius: 43,
                      blur: 24,
                      child: Center(
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 46,
                          color: isDark
                              ? AppTheme.primaryLightColor
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Quick Access",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Use biometric authentication to unlock your account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassGradientButton(
                    text: _isAuthenticating ? "Verifying..." : "Unlock with Biometrics",
                    onPressed: _isAuthenticating ? null : _authenticate,
                    isLoading: _isAuthenticating,
                    leadingIcon: const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _handleAuthFailure,
                    child: Text(
                      "Sign In with Email",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

