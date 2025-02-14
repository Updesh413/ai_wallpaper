import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PexelsService {
  final String apiKey = dotenv.env['PEXELS_API'] ?? '';

  Future<List<String>> fetchWallpapers(String query, int page) async {
    final url = Uri.parse(
        'https://api.pexels.com/v1/search?query=$query&per_page=20&page=$page');
    final response = await http.get(url, headers: {'Authorization': apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(
          data['photos'].map((photo) => photo['src']['large']));
    } else {
      throw Exception('Failed to load wallpapers: ${response.body}');
    }
  }
}
