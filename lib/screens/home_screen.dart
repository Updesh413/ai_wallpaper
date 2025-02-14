import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/pexels_service.dart';
import '../widgets/custom_scaffold.dart';

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

  @override
  void initState() {
    super.initState();
    fetchWallpapers();
    _scrollController.addListener(_scrollListener);
  }

  void fetchWallpapers() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      final fetchedWallpapers =
          await _pexelsService.fetchWallpapers('nature', page);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    // print("User Photo URL: ${FirebaseAuth.instance.currentUser?.photoURL}");
    return CustomScaffold(
      title: 'Wallpapers',
      userId: widget.userId,
      userEmail: widget.userEmail,
      userName: widget.userName,
      body: Stack(
        children: [
          Positioned.fill(
            child: wallpapers.isNotEmpty
                ? FadeInImage.assetNetwork(
                    placeholder: 'assets/img4.webp',
                    image: wallpapers[0],
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/img4.webp',
                    fit: BoxFit.cover,
                  ),
          ),
          SafeArea(
            child: Column(
              children: [
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
          ),
        ],
      ),
    );
  }
}
