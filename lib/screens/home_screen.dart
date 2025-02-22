import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/biometric_service.dart';
import '../services/pexels_service.dart';
import '../widgets/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    fetchWallpapers();
    _scrollController.addListener(_scrollListener);
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
        () => _biometricEnabled = prefs.getBool('biometricEnabled') ?? false);
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
      final fetchedWallpapers = await _pexelsService.fetchWallpapers(
        selectedCategory == 'All' ? 'wallpapers' : selectedCategory,
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
    fetchWallpapers();
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
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: wallpapers[index],
                          fit: BoxFit.cover,
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
