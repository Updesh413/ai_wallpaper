import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../../../features/wallpaper/presentation/screens/home_screen.dart';
import 'login_screen.dart';
import '../providers/auth_provider.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  _BiometricAuthScreenState createState() => _BiometricAuthScreenState();
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
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } else {
        if (mounted) _handleAuthFailure();
      }
    } catch (e) {
      print("Biometric authentication error: $e");
      if (mounted) _handleAuthFailure();
    }
    if (mounted) setState(() => _isAuthenticating = false);
  }

  void _handleAuthFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Authentication failed. Please log in again.')),
    );
    // Sign out to ensure clean state
    context.read<UserAuthProvider>().signOut();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAuthenticating) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
