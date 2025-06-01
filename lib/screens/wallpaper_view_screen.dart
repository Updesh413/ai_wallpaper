import 'dart:io';
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
      appBar: AppBar(
        title: const Text('Wallpaper'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          if (_settingWallpaper)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _settingWallpaper
                      ? null
                      : () => _setWallpaper(context, widget.imageUrl,
                          WallpaperManager.HOME_SCREEN),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.green,
                    side: const BorderSide(
                      color: Colors.greenAccent,
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Set as Home Screen Wallpaper',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _settingWallpaper
                      ? null
                      : () => _setWallpaper(context, widget.imageUrl,
                          WallpaperManager.LOCK_SCREEN),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.green,
                    side: const BorderSide(
                      color: Colors.greenAccent,
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Set as Lock Screen Wallpaper',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _settingWallpaper
                      ? null
                      : () => _setWallpaper(context, widget.imageUrl,
                          WallpaperManager.BOTH_SCREEN),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.green,
                    side: const BorderSide(
                      color: Colors.greenAccent,
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Set as Both Screen Wallpaper',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      _settingWallpaper ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.redAccent,
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
