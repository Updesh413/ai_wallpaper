import '../entities/wallpaper.dart';

abstract class WallpaperRepository {
  Future<List<WallpaperEntity>> getWallpapers(String query, int page);
}
