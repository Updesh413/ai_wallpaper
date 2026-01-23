import '../../../../core/usecases/usecase.dart';
import '../entities/wallpaper.dart';
import '../repositories/wallpaper_repository.dart';

class GetWallpapers implements UseCase<List<WallpaperEntity>, GetWallpapersParams> {
  final WallpaperRepository repository;

  GetWallpapers(this.repository);

  @override
  Future<List<WallpaperEntity>> call(GetWallpapersParams params) async {
    return await repository.getWallpapers(params.query, params.page);
  }
}

class GetWallpapersParams {
  final String query;
  final int page;

  GetWallpapersParams({required this.query, required this.page});
}
