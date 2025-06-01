import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/biometric_service.dart';
import '../services/pexels_service.dart';
import '../widgets/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wallpaper_view_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final String? photoURL;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.photoURL,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PexelsService _pexelsService = PexelsService();
  List<String> wallpapers = [];
  bool isLoading = false;
  int page = 1;
  final ScrollController _scrollController = ScrollController();
  bool _biometricEnabled = false;

  List<String> categories = [
    'All',
    'Nature',
    'Space',
    'Technology',
    'Abstract',
    'Animals',
    'Cars',
    'City',
    'Sports'
  ];
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    fetchWallpapers(); // Fetch random wallpapers on app launch
    _scrollController.addListener(_scrollListener);
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometricEnabled') ?? false;
    setState(() => _biometricEnabled = enabled);

    // Show biometric prompt if disabled
    if (!enabled) {
      Future.delayed(Duration.zero, () => _showBiometricPrompt());
    }
  }

  void _showBiometricPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometric Login?'),
        content: const Text(
            'For faster and more secure logins, would you like to enable biometric authentication?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final prefs = await SharedPreferences.getInstance();
              final bioService = BiometricService(prefs);

              if (await bioService.isBiometricSupported()) {
                final authenticated = await bioService.authenticate();
                if (authenticated) {
                  await bioService.enableBiometric(true);
                  setState(() => _biometricEnabled = true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Biometric enabled')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometric not supported')),
                );
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricSwitch() {
    return ListTile(
      title: const Text('Enable Biometric Authentication'),
      trailing: Switch(
        value: _biometricEnabled,
        onChanged: (value) async {
          final prefs = await SharedPreferences.getInstance();
          final bioService = BiometricService(prefs);

          if (await bioService.isBiometricSupported()) {
            final authenticated = await bioService.authenticate();
            if (authenticated) {
              await bioService.enableBiometric(value);
              setState(() => _biometricEnabled = value);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric not supported')),
            );
          }
        },
      ),
    );
  }

  void fetchWallpapers() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      if (page == 1)
        wallpapers.clear(); // Clear wallpapers only when category changes
    });

    try {
      // Generate a random query or category
      final randomQuery = _getRandomQuery();
      final fetchedWallpapers = await _pexelsService.fetchWallpapers(
        randomQuery,
        page,
      );
      setState(() {
        wallpapers.addAll(fetchedWallpapers.toSet().toList());
        page++;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Generate a random query or category
  String _getRandomQuery() {
    final random = Random();
    if (selectedCategory == 'All') {
      // If "All" is selected, pick a random category
      final randomCategory =
          categories[random.nextInt(categories.length - 1) + 1]; // Skip "All"
      return randomCategory.toLowerCase();
    } else {
      // If a specific category is selected, use it
      return selectedCategory.toLowerCase();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      fetchWallpapers();
    }
  }

  void _changeCategory(String category) {
    setState(() {
      selectedCategory = category;
      page = 1; // Reset pagination when category changes
    });
    fetchWallpapers(); // Fetch random wallpapers for the selected category
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: selectedCategory == category,
              onSelected: (_) => _changeCategory(category),
              selectedColor: Colors.blue,
              backgroundColor: Colors.grey[300],
              labelStyle: TextStyle(
                color:
                    selectedCategory == category ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Wallpapers',
      userId: widget.userId,
      userEmail: widget.userEmail,
      userName: widget.userName,
      body: Column(
        children: [
          _buildCategoryBar(), // Show category selector
          Expanded(
            child: wallpapers.isEmpty && isLoading
                ? _buildShimmerEffect()
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: wallpapers.length + (isLoading ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= wallpapers.length) {
                        return _buildShimmerEffect();
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WallpaperViewScreen(
                                imageUrl: wallpapers[index],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: wallpapers[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
