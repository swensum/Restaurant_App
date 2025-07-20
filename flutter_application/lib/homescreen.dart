import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/common/fav_provider.dart';
import 'package:flutter_application/list/viewmore.dart';
import 'package:flutter_application/screen/about_page.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/rating_utils.dart';
import 'package:provider/provider.dart';

class DishesLayout extends StatefulWidget {
  const DishesLayout({super.key});

  @override
  State<DishesLayout> createState() => _DishesLayoutState();
}

class _DishesLayoutState extends State<DishesLayout> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _foodItemsFuture;

  @override
  void initState() {
    super.initState();
    _foodItemsFuture = _supabaseService.getFoodItems();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
    const int itemsLimit = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0, 6.0, 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dishes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ViewMore()),
                  );
                },
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320.0,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _foodItemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('Error in FutureBuilder: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snapshot.error ?? 'An unknown error occurred'}',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final foodItems = snapshot.data ?? [];
              debugPrint('Number of food items: ${foodItems.length}');

              if (foodItems.isEmpty) {
                return const Center(
                  child: Text(
                    'No food items available.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }
              return ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(
                  foodItems
                      .sublist(
                          0,
                          foodItems.length < itemsLimit
                              ? foodItems.length
                              : itemsLimit)
                      .length,
                  (index) {
                    final foodItem = foodItems[index];
                    final foodId =
                        foodItem['id']?.toString() ?? foodItem['name'];
                    return DishImageWidget(
                      category: foodItem['category'],
                      imageUrl: foodItem['image_url'],
                      imageName: foodItem['name'],
                      rating: foodItem['rating'] ?? 0.0,
                      imageWidth: 350.0,
                      imageHeight: 250.0,
                      foodId: foodId, // ✅ pass foodId here
                      onFavoriteTap: (item) {
                        favoriteProvider.addToFavorites(item);
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AboutPage(foodName: foodItem['name']),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DishImageWidget extends StatelessWidget {
  final String imageUrl;
  final String imageName;
  final double rating;
  final String category;
  final Function(FavoriteItem) onFavoriteTap;
  final VoidCallback onTap;
  final String foodId;

  const DishImageWidget({
    super.key,
    required this.imageUrl,
    required this.imageName,
    required this.rating,
    required this.category,
    required this.onFavoriteTap,
    required this.onTap,
    required this.foodId,
    required double imageWidth,
    required double imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: 350.0,
                    height: 250.0,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha((255 * 0.9).toInt())),
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite_border,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        final favoriteItem = FavoriteItem(
                          name: imageName,
                          imageUrl: imageUrl,
                          rating: rating,
                        );
                        onFavoriteTap(favoriteItem);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              imageName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            AverageRatingWidget(
              reviewsFuture: SupabaseService().getReviews(foodId),
              showFiveStars: true,
              iconSize: 15,
              iconColor: AppTheme.secondaryIconColor,
              ratingTextStyle:
                  const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
