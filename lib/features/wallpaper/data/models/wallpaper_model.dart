import '../../domain/entities/wallpaper.dart';

class WallpaperModel extends WallpaperEntity {
  const WallpaperModel({
    required super.imageUrl,
    required super.photographerName,
    required super.photographerUrl,
  });

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      imageUrl: json['src']['portrait'],
      photographerName: json['photographer'],
      photographerUrl: json['photographer_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'src': {'portrait': imageUrl},
      'photographer': photographerName,
      'photographer_url': photographerUrl,
    };
  }
}
