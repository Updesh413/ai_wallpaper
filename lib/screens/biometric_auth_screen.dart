import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  final User user;

  const BiometricAuthScreen({super.key, required this.user});

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: widget.user.uid,
              userEmail: widget.user.email!,
              userName: widget.user.displayName ?? 'User',
            ),
          ),
        );
      } else {
        _handleAuthFailure();
      }
    } catch (e) {
      print("Biometric authentication error: $e");
      _handleAuthFailure();
    }
    setState(() => _isAuthenticating = false);
  }

  void _handleAuthFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Authentication failed. Please log in again.')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
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
