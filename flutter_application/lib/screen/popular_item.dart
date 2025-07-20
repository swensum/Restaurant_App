import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application/list/viewmore.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/common/fav_provider.dart';
import 'package:flutter_application/screen/about_page.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/rating_utils.dart';
import 'package:provider/provider.dart';

class PopularItemsSection extends StatefulWidget {
  const PopularItemsSection({super.key});

  @override
  State<PopularItemsSection> createState() => _PopularItemsSectionState();
}

class _PopularItemsSectionState extends State<PopularItemsSection> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _foodItemsFuture;
  final Map<String, double> _averageRatings = {}; // Store average rating by item id

  @override
  void initState() {
    super.initState();
    _foodItemsFuture = _loadFoodItemsWithRatings();
  }

  Future<List<Map<String, dynamic>>> _loadFoodItemsWithRatings() async {
    final foodItems = await _supabaseService.getFoodItems();
    final topItems = foodItems.take(10).toList();

    // Prefetch ratings for these items
    for (var item in topItems) {
      final itemId = item['id']?.toString() ?? '';
      final reviews = await _supabaseService.getReviews(itemId);
      // Compute average rating or 0 if no reviews
      double avgRating = 0.0;
      if (reviews.isNotEmpty) {
        final total = reviews.fold<double>(
            0.0, (sum, r) => sum + (r['rating'] as double? ?? 0));
        avgRating = total / reviews.length;
      }
      _averageRatings[itemId] = avgRating;
    }

    return topItems;
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _foodItemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with View More
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 35.0, 6.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Popular Items',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ViewMore()),
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

            // Grid view
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10.0),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 30.0,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final imagePath = item['image_url'] ?? '';
                final itemName = item['name'] ?? '';
                final itemPrice = item['price'] ?? 0;
                final itemId = item['id']?.toString() ?? '';
                final itemRating = _averageRatings[itemId] ?? 0.0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AboutPage(foodName: itemName),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.1).toInt()),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: imagePath.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 110,
                                  placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.fastfood, size: 50),
                                )
                              : const Center(child: Icon(Icons.fastfood, size: 50)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                itemName,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                                                          const SizedBox(height: 4),
                              AverageRatingWidget(
                                reviewsFuture: SupabaseService().getReviews(
                                    item['id']?.toString() ?? itemName),
                                showFiveStars:
                                    false, // 👈 This enables 1-star logic
                                iconSize: 16,
                                iconColor: AppTheme.secondaryIconColor,

                                ratingTextStyle: const TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rs. $itemPrice',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      final favoriteItem = FavoriteItem(
                                        name: itemName,
                                        imageUrl: imagePath,
                                        rating: itemRating,
                                      );
                                      favoriteProvider
                                          .addToFavorites(favoriteItem);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '$itemName added to favorites!')),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.defaultIconColor,
                                      ),
                                      child: Icon(
                                        Icons.favorite_border,
                                        size: 18,
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
