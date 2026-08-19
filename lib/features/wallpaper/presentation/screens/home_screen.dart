import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';

import '../../domain/entities/wallpaper.dart';
import '../providers/wallpaper_provider.dart';
import 'wallpaper_view_screen.dart';
import '../../../../services/favorites_service.dart';
import '../../../../screens/explore_tab_screen.dart';
import '../../../../screens/favorites_tab_screen.dart';
import '../../../../screens/profile_tab_screen.dart';
import '../../../../widgets/glass/glass_bottom_nav_bar.dart';
import '../../../../widgets/glass/glass_container.dart';
import '../../../../core/utils/ad_helper.dart';
import '../../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  final List<String> _categories = [
    'All',
    'Nature',
    'Space',
    'Technology',
    'Abstract',
    'Animals',
    'Cars',
    'City',
    'Sports',
    'Cyberpunk',
    'Minimal',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWallpapers();
      context.read<FavoritesService>().initForCurrentUser();
    });

    _scrollController.addListener(_scrollListener);
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Failed to load a banner ad: ${err.message}');
          if (mounted) {
            setState(() {
              _isBannerAdReady = false;
            });
          }
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  void _fetchWallpapers() {
    final query = _getQueryForCategory(_selectedCategory);
    context.read<WallpaperProvider>().fetchWallpapers(query, _page);
    setState(() {
      _page++;
    });
  }

  String _getQueryForCategory(String category) {
    if (category == 'All') {
      final random = Random();
      final randomCategory =
          _categories[random.nextInt(_categories.length - 1) + 1];
      return randomCategory.toLowerCase();
    } else {
      return category.toLowerCase();
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 150) {
      final provider = context.read<WallpaperProvider>();
      if (!provider.isLoading) {
        _fetchWallpapers();
      }
    }
  }

  void _changeCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _page = 1;
    });
    final query = _getQueryForCategory(category);
    context.read<WallpaperProvider>().fetchWallpapers(query, 1);
  }

  void _selectCategoryFromExplore(String category) {
    setState(() {
      _currentTabIndex = 0;
      _selectedCategory = category;
      _page = 1;
    });
    final query = category.toLowerCase();
    context.read<WallpaperProvider>().fetchWallpapers(query, 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildTopAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          // Frosted App Logo Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(6),
              borderRadius: 21,
              blur: 16,
              child: Hero(
                tag: 'app_logo',
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // App Title
          Text(
            "AI Wallpaper",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),

          // Subscribe / Premium Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text("Premium Plans Coming Soon!"),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: const Color(0xFF1E293B),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9500).withValues(alpha: 0.18),
                    const Color(0xFFFFCC00).withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: Lottie.asset(
                      'assets/subscribe.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'VIP',
                    style: TextStyle(
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => _changeCategory(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: AppTheme.primaryGradient,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.7)),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.8)),
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerGrid(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 170),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallpaperCard(WallpaperEntity wallpaper, bool isDark) {
    final favoritesService = context.watch<FavoritesService>();
    final isFavorite = favoritesService.isFavorite(wallpaper.imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, a1, a2) => WallpaperViewScreen(
              imageUrl: wallpaper.imageUrl,
              photographerName: wallpaper.photographerName,
              photographerUrl: wallpaper.photographerUrl,
            ),
            transitionsBuilder: (context, a1, a2, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Cached Network Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: wallpaper.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    child: const Icon(Icons.error_outline),
                  ),
                ),
              ),

              // Favorite Heart Button (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => favoritesService.toggleFavorite(wallpaper),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 16,
                      color: isFavorite ? const Color(0xFFFF2D55) : Colors.white,
                    ),
                  ),
                ),
              ),

              // Photographer attribution badge (Bottom)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final url = wallpaper.photographerUrl;
                    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    borderRadius: 14,
                    blur: 14,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }

  Widget _buildWallpapersTab(bool isDark) {
    return Column(
      children: [
        _buildTopAppBar(isDark),
        _buildCategoryBar(isDark),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<WallpaperProvider>(
            builder: (context, provider, child) {
              final wallpapers = provider.wallpapers;
              final isLoading = provider.isLoading;

              if (wallpapers.isEmpty && isLoading) {
                return _buildShimmerGrid(isDark);
              }

              if (wallpapers.isEmpty && provider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchWallpapers,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() => _page = 1);
                  _fetchWallpapers();
                },
                child: GridView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 170),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: wallpapers.length + (isLoading ? 2 : 0),
                  itemBuilder: (context, index) {
                    if (index >= wallpapers.length) {
                      return Shimmer.fromColors(
                        baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }
                    final wallpaper = wallpapers[index];
                    return _buildWallpaperCard(wallpaper, isDark);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          SafeArea(
            bottom: false,
            child: _buildWallpapersTab(isDark),
          ),
          ExploreTabScreen(
            onSelectCategory: _selectCategoryFromExplore,
          ),
          FavoritesTabScreen(
            onExplore: () => setState(() => _currentTabIndex = 0),
          ),
          const ProfileTabScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Ad displayed clearly above the floating bottom navigation bar
          if (_isBannerAdReady && _bannerAd != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),

          GlassBottomNavBar(
            currentIndex: _currentTabIndex,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            items: const [
              GlassBottomNavBarItem(
                icon: Icons.grid_view_rounded,
                activeIcon: Icons.grid_view_rounded,
                label: "Home",
              ),
              GlassBottomNavBarItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: "Explore",
              ),
              GlassBottomNavBarItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: "Favorites",
              ),
              GlassBottomNavBarItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: "Profile",
              ),
            ],
          ),
        ],
      ),
    );
  }
}