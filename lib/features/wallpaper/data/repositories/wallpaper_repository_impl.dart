import '../../../../core/error/failures.dart';
import '../../domain/entities/wallpaper.dart';
import '../../domain/repositories/wallpaper_repository.dart';
import '../datasources/wallpaper_remote_data_source.dart';

class WallpaperRepositoryImpl implements WallpaperRepository {
  final WallpaperRemoteDataSource remoteDataSource;

  WallpaperRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<WallpaperEntity>> getWallpapers(String query, int page) async {
    try {
      return await remoteDataSource.getWallpapers(query, page);
    } catch (e) {
      // In a real app, check for specific exceptions
      throw const ServerFailure('An error occurred while fetching wallpapers');
    }
  }
}
