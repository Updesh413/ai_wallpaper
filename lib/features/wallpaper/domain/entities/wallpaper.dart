import 'package:equatable/equatable.dart';

class WallpaperEntity extends Equatable {
  final String imageUrl;
  final String photographerName;
  final String photographerUrl;

  const WallpaperEntity({
    required this.imageUrl,
    required this.photographerName,
    required this.photographerUrl,
  });

  @override
  List<Object?> get props => [imageUrl, photographerName, photographerUrl];
}
