import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../../../../widgets/loading_button.dart';
import '../../../../services/checkinternet_service.dart';
import '../../../wallpaper/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    bool hasInternet = await checkInternetConnection(context);
    if (!hasInternet) return;

    final authProvider = context.read<UserAuthProvider>();
    bool success = await authProvider.signInWithGoogle();

    if (success && mounted) {
       Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? "Sign-in failed"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _signInWithEmail(BuildContext context) async {
    bool hasInternet = await checkInternetConnection(context);
    if (!hasInternet) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    final authProvider = context.read<UserAuthProvider>();
    bool success = await authProvider.signInWithEmail(email, password);

    if (success && mounted) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? "Sign-in failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<UserAuthProvider>();
    final isLoading = authProvider.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: Image.asset(
                'assets/img2.webp',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(seconds: 5),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const Text(
                            "Sign in to get started",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Email",
                              hintStyle: TextStyle(
                                color: Colors.white70,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.white70,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white70,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.greenAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.white70,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white70,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.greenAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          LoadingButton(
                            onPressed: isLoading ? null : () => _signInWithEmail(context),
                            isLoading: isLoading, // Note: Loading state is shared in provider, might be granular if needed
                            text: "Sign in",
                            backgroundColor: Colors.blue,
                            borderColor: Colors.lightBlueAccent,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white70)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("OR",
                                    style: TextStyle(color: Colors.white70)),
                              ),
                              Expanded(child: Divider(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LoadingButton(
                            onPressed: isLoading ? null : () => _signInWithGoogle(context),
                            isLoading: isLoading,
                            text: "Continue with Google",
                            backgroundColor: Colors.lightGreen,
                            borderColor: Colors.greenAccent,
                            leadingIcon: Image.asset(
                              'assets/google_logo.png',
                              height: 30,
                              width: 30,
                            ),
                          ),
                          const SizedBox(height: 5),
                          TextButton(
                            child: const Text(
                                'Don\'t have an account? Register here',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
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
        ],
      ),
    );
  }
}
