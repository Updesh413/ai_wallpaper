import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class WallpaperViewScreen extends StatefulWidget {
  final String imageUrl;

  const WallpaperViewScreen({super.key, required this.imageUrl});

  @override
  State<WallpaperViewScreen> createState() => _WallpaperViewScreenState();
}

class _WallpaperViewScreenState extends State<WallpaperViewScreen> {
  bool _settingWallpaper = false;

  Future<void> _setWallpaper(
      BuildContext context, String url, int location) async {
    try {
      setState(() {
        _settingWallpaper = true;
      });

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_wallpaper.jpg';

      await Dio().download(url, filePath);

      bool result =
          await WallpaperManager.setWallpaperFromFile(filePath, location);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper set successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to set wallpaper')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _settingWallpaper = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen Wallpaper
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error, color: Colors.white)),
            ),
          ),

          // Top bar with back and title
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Row(
                children: [
                  // Back button with dark circle background (no blur needed here)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Blurred "Wallpaper" title
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Wallpaper',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating buttons at bottom
          if (_settingWallpaper)
            const Center(child: CircularProgressIndicator())
          else
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                    bottom: 24.0, left: 24.0, right: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      label: 'Set as Home Screen Wallpaper',
                      onTap: () => _setWallpaper(context, widget.imageUrl,
                          WallpaperManager.HOME_SCREEN),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      label: 'Set as Lock Screen Wallpaper',
                      onTap: () => _setWallpaper(context, widget.imageUrl,
                          WallpaperManager.LOCK_SCREEN),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      label: 'Set as Both Screen Wallpaper',
                      onTap: () => _setWallpaper(context, widget.imageUrl,
                          WallpaperManager.BOTH_SCREEN),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    Color color = Colors.green,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}
