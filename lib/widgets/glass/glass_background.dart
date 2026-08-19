import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GlassBackground extends StatefulWidget {
  final Widget child;
  final bool showOrbs;
  final String? backgroundImage;
  final double imageOpacity;

  const GlassBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
    this.backgroundImage,
    this.imageOpacity = 0.25,
  });

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Base Background Canvas
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? AppTheme.meshGradientDark
                      : AppTheme.meshGradientLight,
                ),
              ),
            ),
          ),

          // Optional Background Image / Wallpaper
          if (widget.backgroundImage != null)
            Positioned.fill(
              child: Opacity(
                opacity: widget.imageOpacity,
                child: Image.asset(
                  widget.backgroundImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Ambient Animated Glowing Orbs
          if (widget.showOrbs)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final progress = _controller.value;
                    final sinVal = math.sin(progress * math.pi);
                    final cosVal = math.cos(progress * math.pi);

                    return Stack(
                      children: [
                        // Orb 1: Cyan / Blue Glow Top Left
                        Positioned(
                          top: -60 + (sinVal * 40),
                          left: -60 + (cosVal * 30),
                          child: _GlowingOrb(
                            size: size.width * 0.85,
                            color: isDark
                                ? const Color(0xFF0072FF).withValues(alpha: 0.35)
                                : const Color(0xFF00C6FF).withValues(alpha: 0.40),
                            blur: 90,
                          ),
                        ),

                        // Orb 2: Purple / Magenta Glow Bottom Right
                        Positioned(
                          bottom: -80 - (cosVal * 40),
                          right: -80 - (sinVal * 35),
                          child: _GlowingOrb(
                            size: size.width * 0.9,
                            color: isDark
                                ? const Color(0xFF7928CA).withValues(alpha: 0.30)
                                : const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                            blur: 100,
                          ),
                        ),

                        // Orb 3: Center Accent Glow
                        Positioned(
                          top: size.height * 0.35 + (sinVal * 30),
                          right: -40 + (cosVal * 25),
                          child: _GlowingOrb(
                            size: size.width * 0.65,
                            color: isDark
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.20)
                                : const Color(0xFF3880FF).withValues(alpha: 0.25),
                            blur: 80,
                          ),
                        ),

                        // Orb 4: Soft Accent Bottom Left
                        Positioned(
                          bottom: size.height * 0.15 - (sinVal * 25),
                          left: -50 - (cosVal * 20),
                          child: _GlowingOrb(
                            size: size.width * 0.55,
                            color: isDark
                                ? const Color(0xFFFF0080).withValues(alpha: 0.18)
                                : const Color(0xFFFF6480).withValues(alpha: 0.20),
                            blur: 85,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Main Foreground Content
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _GlowingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;

  const _GlowingOrb({
    required this.size,
    required this.color,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.2, 1.0],
        ),
      ),
    );
  }
}
