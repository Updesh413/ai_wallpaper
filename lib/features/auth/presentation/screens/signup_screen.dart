import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../../widgets/loading_button.dart';
import '../../../../services/checkinternet_service.dart';
import '../../../wallpaper/presentation/screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordsMatch = true;
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

    // Add listeners
    _passwordController.addListener(_validatePasswords);
    _confirmPasswordController.addListener(_validatePasswords);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswords() {
    setState(() {
      _passwordsMatch =
          _passwordController.text == _confirmPasswordController.text;
    });
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

  Future<void> _register(BuildContext context) async {
    bool hasInternet = await checkInternetConnection(context);
    if (!hasInternet) return;
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content: Text(
                "Please fill in all fields")),
      );
      return;
    }

    if (!_passwordsMatch) {
       ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content: Text(
                "Passwords do not match")),
      );
       return;
    }

    final authProvider = context.read<UserAuthProvider>();
    bool success = await authProvider.signUp(email, password);

    if (success && mounted) {
        // Ideally send verification email inside provider logic or here if user object returned
        // For now, assuming success leads to auto login or back to login
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
              content: Text(
                  "Account created! Please login.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const LoginScreen()),
        );
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? "Registration failed")),
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
                'assets/img3.webp',
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
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
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
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
                          TextField(
                            controller: _confirmPasswordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: "Confirm Password",
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
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _passwordsMatch
                                      ? Colors.white70
                                      : Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _passwordsMatch
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          if (!_passwordsMatch)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Passwords do not match",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          const SizedBox(height: 10),
                          LoadingButton(
                            onPressed: isLoading ? null : () => _register(context),
                            isLoading: isLoading,
                            text: "Register",
                            backgroundColor: Colors.blue,
                            borderColor: Colors.lightBlueAccent,
                          ),
                          const SizedBox(height: 10),
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
                                'Already have an account? Login here',
                                style: TextStyle(color: Colors.white)),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
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
