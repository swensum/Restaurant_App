import 'package:admin_panel/pages/edit_food_page.dart';
import 'package:admin_panel/utils/rating_utils.dart';
import 'package:admin_panel/utils/supabase_clients.dart';
import 'package:admin_panel/utils/theme.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Map<String, dynamic>>> _foodItemsFuture;
  String selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  void _loadFoodItems() {
    _foodItemsFuture = _supabaseService.getFoodItems();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.2).toInt()),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search food items...',
                hintStyle: TextStyle(color: Color.fromARGB(153, 185, 184, 184)),
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),

        // Food container with categories and items
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).bottomAppBarTheme.color ?? Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(35),
              ),
            ),
            padding:  EdgeInsets.only(
              top: 10,
              left: 16,
              right: 16,
             bottom: MediaQuery.of(context).viewPadding.bottom + 60,
            ),

            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _foodItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final items = snapshot.data ?? [];
                final categories = <String>{};
                for (var item in items) {
                  final category = (item['category'] ?? '').toString();
                  if (category.isNotEmpty) {
                    categories.add(category);
                  }
                }
                final categoryList = ['All', ...categories];

                // Filter items by availability AND category
                var filteredItems =
                    items.where((item) {
                      final available = item['availability'] == true;
                      final matchesCategory =
                          selectedCategory == 'All' ||
                          item['category'] == selectedCategory;
                      return available && matchesCategory;
                    }).toList();

                // Further filter by search query
                if (_searchQuery.isNotEmpty) {
                  filteredItems =
                      filteredItems.where((item) {
                        final name =
                            (item['name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                }

                if (filteredItems.isEmpty) {
                  return const Center(child: Text("No food items found."));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    SizedBox(
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              categoryList.map((category) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedCategory = category;
                                    });
                                  },
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize:
                                          selectedCategory == category
                                              ? 20
                                              : 16,
                                      fontWeight:
                                          selectedCategory == category
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          selectedCategory == category
                                              ? Theme.of(context).primaryColor
                                              : const Color.fromARGB(
                                                98,
                                                0,
                                                0,
                                                0,
                                              ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16,
                                        bottom: 6,
                                      ),
                                      child: Text(category),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15.0,
                              mainAxisSpacing: 20.0,
                              childAspectRatio: 0.85,
                            ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final image = item['image_url'] ?? '';
                          final name = item['name'] ?? '';
                          final price = item['price'] ?? 0;

                          return GestureDetector(
                            onTap: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditFoodPage(foodItem: item),
                                ),
                              );

                              // Reload the list if item was updated
                              if (updated == true) {
                                setState(() {
                                  _foodItemsFuture =
                                      _supabaseService.getFoodItems();
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      (255 * 0.1).toInt(),
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child:
                                        image.isNotEmpty
                                            ? Image.network(
                                              image,
                                              fit: BoxFit.cover,
                                              height: 110,
                                              width: double.infinity,
                                            )
                                            : const Icon(
                                              Icons.fastfood,
                                              size: 80,
                                            ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        AverageRatingWidget(
                                          reviewsFuture: _supabaseService
                                              .getReviews(
                                                item['id']?.toString() ?? name,
                                              ),
                                          iconSize: 16,
                                          showFiveStars: false,
                                          iconColor: Colors.grey,
                                          ratingTextStyle: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Rs. $price",
                                          style: const TextStyle(
                                            color: AppTheme.defaultIconColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
