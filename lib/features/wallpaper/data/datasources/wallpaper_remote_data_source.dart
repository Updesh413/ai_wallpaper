import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/error/failures.dart';
import '../models/wallpaper_model.dart';

abstract class WallpaperRemoteDataSource {
  Future<List<WallpaperModel>> getWallpapers(String query, int page);
}

class WallpaperRemoteDataSourceImpl implements WallpaperRemoteDataSource {
  final http.Client client;

  WallpaperRemoteDataSourceImpl({required this.client});

  @override
  Future<List<WallpaperModel>> getWallpapers(String query, int page) async {
    final apiKey = dotenv.env['PEXELS_API'] ?? '';
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
        'https://api.pexels.com/v1/search?query=$encodedQuery&per_page=20&page=$page');

    final response = await client.get(
      url,
      headers: {'Authorization': apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<WallpaperModel>.from(
        data['photos'].map((photo) => WallpaperModel.fromJson(photo)),
      );
    } else {
      throw const ServerFailure('Failed to fetch wallpapers');
    }
  }
}
