import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/wallpaper/domain/entities/wallpaper.dart';

class FavoritesService extends ChangeNotifier {
  static const String _prefPrefix = 'user_favorites_';
  List<WallpaperEntity> _favorites = [];
  String? _currentUserId;
  bool _isLoading = false;

  List<WallpaperEntity> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  FavoritesService() {
    initForCurrentUser();
  }

  /// Initialize and load favorites for the active user (or guest)
  Future<void> initForCurrentUser([String? explicitUserId]) async {
    final userId = explicitUserId ?? FirebaseAuth.instance.currentUser?.uid;
    _currentUserId = userId;

    await _loadFromLocalCache();
    if (userId != null && userId.isNotEmpty) {
      await _syncFromFirestore(userId);
    }
  }

  /// Load immediately from SharedPreferences for instant UI rendering
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${_currentUserId ?? 'guest'}';
      final rawList = prefs.getStringList(storageKey) ?? [];

      _favorites = rawList.map((item) {
        final Map<String, dynamic> map = jsonDecode(item);
        return WallpaperEntity(
          imageUrl: map['imageUrl'] as String? ?? '',
          photographerName: map['photographerName'] as String? ?? 'Unknown',
          photographerUrl: map['photographerUrl'] as String? ?? '',
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local favorites: $e');
    }
  }

  /// Fetch and merge latest favorites from Cloud Firestore
  Future<void> _syncFromFirestore(String userId) async {
    try {
      _isLoading = true;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['favorites'] is List) {
          final cloudList = data['favorites'] as List;
          final List<WallpaperEntity> parsedCloud = [];

          for (final item in cloudList) {
            if (item is Map) {
              parsedCloud.add(
                WallpaperEntity(
                  imageUrl: item['imageUrl'] as String? ?? '',
                  photographerName: item['photographerName'] as String? ?? 'Unknown',
                  photographerUrl: item['photographerUrl'] as String? ?? '',
                ),
              );
            }
          }

          _favorites = parsedCloud;
          await _saveToLocalCache();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing favorites from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save current favorites to SharedPreferences
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = '$_prefPrefix${_currentUserId ?? 'guest'}';

      final encodedList = _favorites.map((w) {
        return jsonEncode({
          'imageUrl': w.imageUrl,
          'photographerName': w.photographerName,
          'photographerUrl': w.photographerUrl,
        });
      }).toList();

      await prefs.setStringList(storageKey, encodedList);
    } catch (e) {
      debugPrint('Error saving favorites locally: $e');
    }
  }

  /// Sync current favorites to Cloud Firestore
  Future<void> _syncToFirestore() async {
    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return;

    try {
      final firestoreList = _favorites.map((w) => {
        'imageUrl': w.imageUrl,
        'photographerName': w.photographerName,
        'photographerUrl': w.photographerUrl,
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'favorites': firestoreList},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving favorites to Firestore: $e');
    }
  }

  /// Check if a wallpaper is in favorites
  bool isFavorite(String imageUrl) {
    return _favorites.any((w) => w.imageUrl == imageUrl);
  }

  /// Toggle favorite status (adds if missing, removes if present)
  Future<bool> toggleFavorite(WallpaperEntity wallpaper) async {
    final index = _favorites.indexWhere((w) => w.imageUrl == wallpaper.imageUrl);
    final bool isAdded = index < 0;

    if (isAdded) {
      _favorites.insert(0, wallpaper);
    } else {
      _favorites.removeAt(index);
    }

    notifyListeners();

    // Persist locally and in the cloud
    await _saveToLocalCache();
    await _syncToFirestore();

    return isAdded;
  }

  /// Reset memory state when signing out
  void clearForLogout() {
    _favorites = [];
    _currentUserId = null;
    notifyListeners();
  }
}
