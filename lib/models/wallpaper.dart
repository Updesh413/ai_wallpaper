class Wallpaper {
  final String imageUrl;
  final String photographerName;
  final String photographerUrl;

  Wallpaper({
    required this.imageUrl,
    required this.photographerName,
    required this.photographerUrl,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      imageUrl: json['src']['portrait'],
      photographerName: json['photographer'],
      photographerUrl: json['photographer_url'],
    );
  }
}
