import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../../services/checkinternet_service.dart';
import '../../../wallpaper/presentation/screens/home_screen.dart';
import '../../../../widgets/glass/glass_background.dart';
import '../../../../widgets/glass/glass_container.dart';
import '../../../../widgets/glass/glass_text_field.dart';
import '../../../../widgets/glass/glass_button.dart';
import '../../../../services/favorites_service.dart';
import '../../../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardScaleAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isGoogleLoading = false;
  bool _isRegisterLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();

    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    bool hasInternet = await checkInternetConnection(context);
    if (!hasInternet || !mounted) return;

    setState(() => _isGoogleLoading = true);
    final authProvider = context.read<UserAuthProvider>();
    bool success = await authProvider.signInWithGoogle();

    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (success) {
        context.read<FavoritesService>().initForCurrentUser(authProvider.user?.uid);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const HomeScreen(),
            transitionsBuilder: (context, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(authProvider.errorMessage ?? "Google sign-in failed"),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Please fill in all fields"),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Password must be at least 6 characters"),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("Passwords do not match"),
            ],
          ),
          backgroundColor: Colors.redAccent.shade700,
        ),
      );
      return;
    }

    bool hasInternet = await checkInternetConnection(context);
    if (!hasInternet || !mounted) return;

    setState(() => _isRegisterLoading = true);
    final authProvider = context.read<UserAuthProvider>();
    bool success = await authProvider.signUp(email, password);

    if (mounted) {
      setState(() => _isRegisterLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text("Account created successfully! Please sign in."),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => const LoginScreen(),
            transitionsBuilder: (context, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(authProvider.errorMessage ?? "Registration failed"),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent.shade700,
          ),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, a1, a2) => const LoginScreen(),
        transitionsBuilder: (context, a1, a2, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: a1.drive(tween),
            child: FadeTransition(opacity: a1, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final hasConfirm = confirmPassword.isNotEmpty;
    final passwordsMatch = password.isNotEmpty && password == confirmPassword;

    return GlassBackground(
      backgroundImage: 'assets/img3.webp',
      imageOpacity: isDark ? 0.15 : 0.08,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Header & Logo
                  SlideTransition(
                    position: _headerSlideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Frosted Logo Badge
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 26,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 40,
                              blur: 24,
                              child: Hero(
                                tag: 'app_logo',
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Join to discover high-res AI wallpapers",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Frosted Registration Card
                  SlideTransition(
                    position: _cardSlideAnimation,
                    child: ScaleTransition(
                      scale: _cardScaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: GlassContainer(
                          blur: 24,
                          borderRadius: 28,
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field
                                GlassTextField(
                                  controller: _emailController,
                                  hintText: "Email address",
                                  labelText: "Email",
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                                ),

                                const SizedBox(height: 16),

                                // Password Field
                                GlassTextField(
                                  controller: _passwordController,
                                  hintText: "Create password (min. 6 chars)",
                                  labelText: "Password",
                                  isPassword: true,
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                ),

                                const SizedBox(height: 16),

                                // Confirm Password Field
                                GlassTextField(
                                  controller: _confirmPasswordController,
                                  hintText: "Confirm password",
                                  labelText: "Confirm Password",
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                                  onSubmitted: (_) => _register(),
                                ),

                                // Live Password Match Indicator
                                if (hasConfirm) ...[
                                  const SizedBox(height: 10),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: passwordsMatch
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : Colors.redAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: passwordsMatch
                                            ? Colors.green.withValues(alpha: 0.4)
                                            : Colors.redAccent.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          passwordsMatch
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          size: 16,
                                          color: passwordsMatch
                                              ? Colors.greenAccent.shade400
                                              : Colors.redAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          passwordsMatch
                                              ? "Passwords match perfectly"
                                              : "Passwords do not match",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: passwordsMatch
                                                ? (isDark
                                                    ? Colors.greenAccent.shade400
                                                    : Colors.green.shade800)
                                                : (isDark
                                                    ? Colors.redAccent.shade100
                                                    : Colors.redAccent.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 22),

                                // Register Button
                                GlassGradientButton(
                                  text: "Create Account",
                                  onPressed: _register,
                                  isLoading: _isRegisterLoading,
                                  trailingIcon: const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Frosted Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              isDark
                                                  ? Colors.white24
                                                  : Colors.black12,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: Text(
                                        "OR",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              isDark
                                                  ? Colors.white24
                                                  : Colors.black12,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Google Sign In Button
                                GlassSocialButton(
                                  text: "Continue with Google",
                                  isLoading: _isGoogleLoading,
                                  icon: Image.asset(
                                    'assets/google_logo.png',
                                    height: 22,
                                    width: 22,
                                  ),
                                  onPressed: _signInWithGoogle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer Login Link
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: GestureDetector(
                      onTap: _navigateToLogin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.primaryLightColor
                                      : AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
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

