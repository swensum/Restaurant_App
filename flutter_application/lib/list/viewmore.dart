import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/common/fav_provider.dart';
import 'package:flutter_application/common/food_data.dart';
import 'package:flutter_application/screen/about_page.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/rating_utils.dart';
import 'package:provider/provider.dart';

class ViewMore extends StatefulWidget {
  const ViewMore({super.key});

  @override
  State<ViewMore> createState() => _ViewMoreState();
}

class _ViewMoreState extends State<ViewMore> {
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

    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        title: Text('Food List',style: Theme.of(context).textTheme.displayLarge,),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _foodItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
          if (foodItems.isEmpty) {
            return const Center(
              child: Text(
                'No food items available.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final foodItem = FoodItem.fromMap(foodItems[index]);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AboutPage(foodName: foodItem.name),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.2).toInt()),
                          spreadRadius: 1,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0),
                          ),
                          child: foodItem.imageUrl.isNotEmpty
                              ? Image.network(
                                  foodItem.imageUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood),
                                  ),
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
                            padding: const EdgeInsets.only(
                                left: 8.0, top: 10.0, right: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                Text(
                                  foodItem.name,
                                 style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                // Rating + Count
                                AverageRatingWidget(
                                  reviewsFuture: SupabaseService()
                                      .getReviews(foodItem.id.toString()),
                                  showFiveStars: true,
                                  iconSize: 16,
                                  iconColor: AppTheme.secondaryIconColor,
                                  ratingTextStyle: const TextStyle(
                                      fontSize: 13, color: Colors.black54),
                                ),

                                const SizedBox(height: 25),

                                // Price + Favorite
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rs. ${foodItem.price.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        favoriteProvider.addToFavorites(
                                          FavoriteItem(
                                            name: foodItem.name,
                                            imageUrl: foodItem.imageUrl,
                                            rating: foodItem.rating ?? 0.0,
                                          ),
                                        );

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '${foodItem.name} added to favorites'),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:  AppTheme.defaultIconColor,
                                        ),
                                        child:  Icon(
                                          Icons.favorite_border,
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
            },
          );
        },
      ),
    );
  }
}
