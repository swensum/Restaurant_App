import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/screen/about_page.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/rating_utils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/common/fav_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FoodList extends StatefulWidget {
  final String category;

  const FoodList({super.key, required this.category});

  @override
  State<FoodList> createState() => _FoodListState();
}

class _FoodListState extends State<FoodList> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _foodItemsFuture;

  @override
  void initState() {
    super.initState();
    _foodItemsFuture = _supabaseService.getFoodItemsByCategory(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        title: Text(widget.category),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _foodItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final foodItems = snapshot.data ?? [];

          return foodItems.isEmpty
              ? const Center(child:  Text('No items available'))
              : ListView.separated(
                  itemCount: foodItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = foodItems[index];
                    return FoodItemWidget(
                      foodItem: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutPage(foodName: item['name']),
                          ),
                        );
                      },
                      supabaseService: _supabaseService, // pass for reuse
                    );
                  },
                );
        },
      ),
    );
  }
}

class FoodItemWidget extends StatelessWidget {
  final Map<String, dynamic> foodItem;
  final VoidCallback onTap;
  final SupabaseService supabaseService;

  const FoodItemWidget({
    super.key,
    required this.foodItem,
    required this.onTap,
    required this.supabaseService,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    final imagePath = foodItem['image_url'] ?? '';
    final name = foodItem['name'] ?? '';
    final rating = foodItem['rating'] ?? 0.0;
    final price = foodItem['price'] ?? 0.0;

    final isAlreadyFavorite = favoriteProvider.favoriteItems.any((item) => item.name == name);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.1).toInt()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: imagePath.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey[300]),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.fastfood),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood),
                      ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      AverageRatingWidget(
                        reviewsFuture: supabaseService.getReviews(foodItem['id'].toString()),
                        showFiveStars: true,
                        iconSize: 16,
                        iconColor: AppTheme.secondaryIconColor,
                        ratingTextStyle: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rs. ${price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (!isAlreadyFavorite) {
                                favoriteProvider.addToFavorites(FavoriteItem(
                                  name: name,
                                  imageUrl: imagePath,
                                  rating: rating,
                                ));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name added to favorites'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Already in favorites'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.defaultIconColor,
                              ),
                              child: Icon(
                                isAlreadyFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 22,
                                color: Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
