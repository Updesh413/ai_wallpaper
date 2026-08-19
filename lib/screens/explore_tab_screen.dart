import 'package:flutter/material.dart';
import '../widgets/glass/glass_text_field.dart';

class ExploreTabScreen extends StatefulWidget {
  final ValueChanged<String> onSelectCategory;

  const ExploreTabScreen({
    super.key,
    required this.onSelectCategory,
  });

  @override
  State<ExploreTabScreen> createState() => _ExploreTabScreenState();
}

class _ExploreTabScreenState extends State<ExploreTabScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Nature',
      'icon': Icons.forest_rounded,
      'image': 'assets/img1.webp',
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'Space',
      'icon': Icons.nights_stay_rounded,
      'image': 'assets/wallpaper1.webp',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Technology',
      'icon': Icons.memory_rounded,
      'image': 'assets/img2.webp',
      'color': const Color(0xFF0072FF),
    },
    {
      'name': 'Abstract',
      'icon': Icons.auto_awesome_rounded,
      'image': 'assets/img3.webp',
      'color': const Color(0xFFFF0080),
    },
    {
      'name': 'Animals',
      'icon': Icons.pets_rounded,
      'image': 'assets/img5.webp',
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Cars',
      'icon': Icons.directions_car_filled_rounded,
      'image': 'assets/img6.webp',
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'City',
      'icon': Icons.location_city_rounded,
      'image': 'assets/img4.webp',
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Sports',
      'icon': Icons.fitness_center_rounded,
      'image': 'assets/wallpaper2.webp',
      'color': const Color(0xFF14B8A6),
    },
    {
      'name': 'Cyberpunk',
      'icon': Icons.bolt_rounded,
      'image': 'assets/wallpaper3.webp',
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Minimal',
      'icon': Icons.crop_square_rounded,
      'image': 'assets/img2.webp',
      'color': const Color(0xFF64748B),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      widget.onSelectCategory(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header & Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Explore",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Find the perfect wallpaper for your screen",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Search Field
                  GlassTextField(
                    controller: _searchController,
                    hintText: "Search wallpapers (e.g. Neon, Anime, Dark)...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmitted,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      onPressed: () => _onSearchSubmitted(_searchController.text),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Popular Categories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 170),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = _categories[index];
                  final name = cat['name'] as String;
                  final icon = cat['icon'] as IconData;
                  final image = cat['image'] as String;
                  final accentColor = cat['color'] as Color;

                  return GestureDetector(
                    onTap: () => widget.onSelectCategory(name),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.35)
                                : accentColor.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            // Background Image Thumbnail
                            Positioned.fill(
                              child: Image.asset(
                                image,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Dark Gradient / Frosted Overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.25),
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Frosted glass border outline
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Icon Badge
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),

                                  // Title
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
