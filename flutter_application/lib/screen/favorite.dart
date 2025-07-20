// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/common/fav_provider.dart';
import 'package:flutter_application/common/food_data.dart';
import 'package:flutter_application/common/provider.dart';
import 'package:flutter_application/screen/about_page.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/rating_utils.dart';
import 'package:provider/provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool isSelectMode = false;
  List<String> selectedItems = [];
  late Future<List<Map<String, dynamic>>> _foodItemsFuture;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _foodItemsFuture = _supabaseService.getFoodItems();
  }

  void addToCart(Map<String, dynamic> foodItem) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
   final FoodItem item = FoodItem.fromMap(foodItem);

    // Add the FoodItem to the cart
    cartProvider.addToCart(item);
  }

  void toggleSelection(String itemName) {
    setState(() {
      if (selectedItems.contains(itemName)) {
        selectedItems.remove(itemName);
      } else {
        selectedItems.add(itemName);
      }
    });
  }

  void removeSelectedItems(FavoriteProvider favoriteProvider) {
    setState(() {
      for (var itemName in selectedItems) {
        final item = favoriteProvider.favoriteItems
            .firstWhere((favItem) => favItem.name == itemName);
        favoriteProvider.removeFromFavorites(item);
      }
      selectedItems.clear();
      isSelectMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected items removed from favorites')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        title: Text('Favorite',style: Theme.of(context).textTheme.displayLarge,),
        actions: [
          if (isSelectMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                removeSelectedItems(favoriteProvider);
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
        ],
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
          if (favoriteProvider.favoriteItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your favorite items are empty!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: favoriteProvider.favoriteItems.length,
            itemBuilder: (context, index) {
              final favoriteItem = favoriteProvider.favoriteItems[index];
              final foodItem = foodItems.firstWhere(
                (item) => item['name'] == favoriteItem.name,
                orElse: () => {
                  'name': favoriteItem.name,
                  'price': 0,
                  'image_url': '',
                  'rating': 0,
                },
              );

              bool isHovered = false;

              return MouseRegion(
                onEnter: (_) => setState(() => isHovered = true),
                onExit: (_) => setState(() => isHovered = false),
                child: GestureDetector(
                  onLongPress: () {
                    setState(() {
                      isSelectMode = true;
                      toggleSelection(favoriteItem.name);
                    });
                  },
                  onTap: () {
                    if (isSelectMode) {
                      toggleSelection(favoriteItem.name);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutPage(
                            foodName: favoriteItem.name,
                          ),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selectedItems.contains(favoriteItem.name)
                          ? Colors.grey[300]
                          : isHovered
                              ? Colors.grey[200]
                              : Colors.white,
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
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            bottomLeft: Radius.circular(10.0),
                          ),
                          child: foodItem['image_url'].isNotEmpty
                              ? Image.network(
                                  foodItem['image_url'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foodItem['name'],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              AverageRatingWidget(
                                reviewsFuture: SupabaseService()
                                    .getReviews(foodItem['id'].toString()),
                                showFiveStars: true,
                                iconSize: 16,
                                iconColor: AppTheme.secondaryIconColor,
                                ratingTextStyle: const TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 3),
                              Text(
                               'Rs. ${foodItem['price']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.defaultIconColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                       
                        SizedBox(
                           width: 60,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () {
                                  addToCart(foodItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${foodItem['name']} added to cart'),
                                    ),
                                  );
                                },
                                child: MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => isHovered = true),
                                  onExit: (_) =>
                                      setState(() => isHovered = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: 60,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? Colors.greenAccent
                                          : AppTheme.defaultIconColor,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    child:  Center(
                                      child: Icon(
                                        Icons.shopping_cart,
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        size: 24,
                                      ),
                                    ),
                                  ),
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
          );
        },
      ),
    );
  }
}
