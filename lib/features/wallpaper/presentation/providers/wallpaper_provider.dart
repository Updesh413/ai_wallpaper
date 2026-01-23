import 'package:flutter/material.dart';
import '../../domain/entities/wallpaper.dart';
import '../../domain/usecases/get_wallpapers.dart';

class WallpaperProvider with ChangeNotifier {
  final GetWallpapers getWallpapersUseCase;

  WallpaperProvider({required this.getWallpapersUseCase});

  List<WallpaperEntity> _wallpapers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WallpaperEntity> get wallpapers => _wallpapers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWallpapers(String query, int page) async {
    if (page == 1) {
      _wallpapers.clear();
      _isLoading = true;
      notifyListeners();
    } else {
       // Optional: add a separate loading state for pagination if needed
       // for now we just rely on the UI checking list length vs total or similar
    }

    try {
      final newWallpapers = await getWallpapersUseCase(GetWallpapersParams(query: query, page: page));
      _wallpapers.addAll(newWallpapers);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
