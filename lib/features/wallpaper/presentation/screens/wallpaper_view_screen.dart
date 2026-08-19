import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/wallpaper.dart';
import '../../../../services/favorites_service.dart';
import '../../../../widgets/glass/glass_container.dart';
import '../../../../widgets/glass/glass_button.dart';
import '../../../../theme/app_theme.dart';

class WallpaperViewScreen extends StatefulWidget {
  final String imageUrl;
  final String photographerName;
  final String photographerUrl;
  final int wallpaperId;

  const WallpaperViewScreen({
    super.key,
    required this.imageUrl,
    this.photographerName = 'Unknown',
    this.photographerUrl = '',
    this.wallpaperId = 0,
  });

  @override
  State<WallpaperViewScreen> createState() => _WallpaperViewScreenState();
}

class _WallpaperViewScreenState extends State<WallpaperViewScreen> {
  bool _settingWallpaper = false;
  String _statusMessage = 'Downloading wallpaper...';

  Future<void> _setWallpaper(int location) async {
    Navigator.of(context).pop(); // Close bottom sheet if open

    try {
      setState(() {
        _settingWallpaper = true;
        _statusMessage = 'Downloading wallpaper...';
      });

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Dio().download(widget.imageUrl, filePath);

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Setting wallpaper...';
      });

      bool result = await WallpaperManager.setWallpaperFromFile(filePath, location);

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Wallpaper set successfully!'),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Failed to set wallpaper'),
                ],
              ),
              backgroundColor: Colors.redAccent.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _settingWallpaper = false;
        });
      }
    }
  }

  void _showSetWallpaperModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Apply Wallpaper",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Choose where you want to set this wallpaper",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              _buildModalOption(
                icon: Icons.phone_android_rounded,
                title: "Home Screen",
                subtitle: "Apply to home screen only",
                onTap: () => _setWallpaper(WallpaperManager.HOME_SCREEN),
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildModalOption(
                icon: Icons.lock_outline_rounded,
                title: "Lock Screen",
                subtitle: "Apply to lock screen only",
                onTap: () => _setWallpaper(WallpaperManager.LOCK_SCREEN),
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildModalOption(
                icon: Icons.splitscreen_rounded,
                title: "Both Screens",
                subtitle: "Apply to both home and lock screens",
                onTap: () => _setWallpaper(WallpaperManager.BOTH_SCREEN),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppTheme.primaryGradient),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesService = context.watch<FavoritesService>();
    final isFavorite = favoritesService.isFavorite(widget.imageUrl);

    final wallpaperObj = WallpaperEntity(
      imageUrl: widget.imageUrl,
      photographerName: widget.photographerName,
      photographerUrl: widget.photographerUrl,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen Wallpaper
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
              ),
            ),
          ),

          // Top App Bar Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GlassIconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Favorite Button
                  GlassIconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 20,
                      color: isFavorite ? const Color(0xFFFF2D55) : Colors.white,
                    ),
                    onPressed: () => favoritesService.toggleFavorite(wallpaperObj),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: _settingWallpaper
                    ? GlassContainer(
                        blur: 24,
                        borderRadius: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GlassGradientButton(
                        text: "Apply Wallpaper",
                        leadingIcon: const Icon(
                          Icons.wallpaper_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _showSetWallpaperModal,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
