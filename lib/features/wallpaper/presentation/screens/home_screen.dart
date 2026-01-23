import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/wallpaper.dart';
import '../providers/wallpaper_provider.dart';
import 'wallpaper_view_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../widgets/custom_scaffold.dart';
import '../../../../services/biometric_service.dart';

class HomeScreen extends StatefulWidget {
  // We can remove these params and use AuthProvider, but to keep CustomScaffold happy for now
  // we might pass them, or better: retrieve from provider inside build.
  // I will make them optional to allow migration or just ignore them if I can get from provider.
  // Actually, for cleanest transition, let's keep the constructor signature compatible if possible
  // or better, update calls to HomeScreen to not pass them.
  // Since I am refactoring navigation in Splash/Login, I will remove them.

  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    // Fetch random wallpapers on app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWallpapers();
    });
    
    _scrollController.addListener(_scrollListener);
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometricEnabled') ?? false;
    setState(() => _biometricEnabled = enabled);

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

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric enabled')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Biometric not supported')),
                  );
                }
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _fetchWallpapers() {
    final randomQuery = _getRandomQuery();
    context.read<WallpaperProvider>().fetchWallpapers(randomQuery, page);
    setState(() {
      page++;
    });
  }

  String _getRandomQuery() {
    final random = Random();
    if (selectedCategory == 'All') {
      final randomCategory =
          categories[random.nextInt(categories.length - 1) + 1];
      return randomCategory.toLowerCase();
    } else {
      return selectedCategory.toLowerCase();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final provider = context.read<WallpaperProvider>();
      if (!provider.isLoading) {
         _fetchWallpapers();
      }
    }
  }

  void _changeCategory(String category) {
    setState(() {
      selectedCategory = category;
      page = 1;
    });
    _fetchWallpapers();
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
    final authProvider = context.watch<UserAuthProvider>();
    final user = authProvider.user;

    // Fallback values if user is null (though normally shouldn't be here if not logged in)
    final userId = user?.uid ?? 'guest';
    final userEmail = user?.email ?? 'guest@example.com';
    final userName = user?.displayName ?? 'Guest';

    return CustomScaffold(
      title: 'Wallpapers',
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: Consumer<WallpaperProvider>(
              builder: (context, provider, child) {
                final wallpapers = provider.wallpapers;
                final isLoading = provider.isLoading;

                if (wallpapers.isEmpty && isLoading) {
                  return _buildShimmerEffect();
                }

                if (wallpapers.isEmpty && provider.errorMessage != null) {
                   return Center(child: Text(provider.errorMessage!));
                }

                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: wallpapers.length + (isLoading ? 2 : 0),
                  itemBuilder: (context, index) {
                    if (index >= wallpapers.length) {
                      return _buildShimmerEffect();
                    }
                    final wallpaper = wallpapers[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WallpaperViewScreen(
                              imageUrl: wallpaper.imageUrl,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: wallpaper.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: Colors.black54,
                                child: GestureDetector(
                                  onTap: () async {
                                    final url = wallpaper.photographerUrl;
                                    if (await canLaunchUrl(Uri.parse(url))) {
                                      await launchUrl(Uri.parse(url),
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundImage: NetworkImage(
                                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(wallpaper.photographerName)}&background=random',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          wallpaper.photographerName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            decoration: TextDecoration.underline,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
