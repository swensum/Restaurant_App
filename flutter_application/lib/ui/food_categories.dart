import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/list/food_list.dart';

class FoodCategories extends StatefulWidget {
  const FoodCategories({super.key});

  @override
  State<FoodCategories> createState() => _FoodCategoriesState();
}

class _FoodCategoriesState extends State<FoodCategories> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, int> _categoryCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final foodItems = await _supabaseService.getFoodItems();
    final Map<String, int> categoryCounts = {};

    for (var item in foodItems) {
      final category = item['category'] ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    setState(() {
      _categoryCounts = categoryCounts;
    });
  }

  Widget buildCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();

    final Map<String, String> imageIcons = {
      'drink': 'assets/icons/drink.jpg',
      'breakfast': 'assets/icons/breakfast.jpg',
      'snacks': 'assets/icons/snacks.jpg',
      'lunch': 'assets/icons/Lunch.jpg',
      'dinner': 'assets/icons/Dinner.jpg',
    };
    for (final key in imageIcons.keys) {
      if (lowerCategory.contains(key)) {
        return Image.asset(
          imageIcons[key]!,
          fit: BoxFit.cover,
        );
      }
    }
    return Icon(
      Icons.fastfood,
      size: 30.0,
      color: Theme.of(context).iconTheme.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Text(
            'Food Categories',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        SizedBox(
          height: 80.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categoryCounts.keys.length,
            itemBuilder: (context, index) {
              final category = _categoryCounts.keys.elementAt(index);
              final itemCount = _categoryCounts[category] ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodList(category: category),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: CategoryItem(
                    iconWidget: buildCategoryIcon(category),
                    name: '$category ($itemCount)',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CategoryItem extends StatelessWidget {
  final Widget iconWidget;
  final String name;

  const CategoryItem({super.key, required this.iconWidget, required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: Container(
        width: 200.0,
        height: 100.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            // Circular Icon
            ClipOval(
              child: SizedBox(
                width: 60.0,
                height: 60.0,
                child: iconWidget,
              ),
            ),
            const SizedBox(width: 10.0),
            // Category Name
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
