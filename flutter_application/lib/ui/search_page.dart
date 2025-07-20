import 'dart:async';  // <-- for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/screen/about_page.dart';
import 'package:flutter_application/theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allFoodItems = [];
  List<Map<String, dynamic>> _filteredFoodItems = [];
  final SupabaseService _supabaseService = SupabaseService();

  List<String> _categories = [];
  String _selectedCategory = 'All';

  Timer? _debounce;  // debounce timer

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterFoodItems();
    });
  }

  Future<void> _fetchFoodItems() async {
    try {
      final foodItems = await _supabaseService.getFoodItems();

      final Set<String> categoriesSet = {'All'};
      for (var item in foodItems) {
        final category = item['category'] ?? 'Uncategorized';
        categoriesSet.add(category);
      }

      setState(() {
        _allFoodItems = foodItems;
        _categories = categoriesSet.toList();
        _filteredFoodItems = _allFoodItems;
      });
    } catch (e) {
      debugPrint('Error fetching food items: $e');
    }
  }

  void _filterFoodItems() {
    final String query = _searchController.text.toLowerCase();

    List<Map<String, dynamic>> tempList;

    if (_selectedCategory == 'All') {
      tempList = _allFoodItems;
    } else {
      tempList = _allFoodItems
          .where((item) =>
              (item['category'] ?? '').toLowerCase() ==
              _selectedCategory.toLowerCase())
          .toList();
    }

    if (query.isNotEmpty) {
      tempList = tempList
          .where((item) => (item['name'] ?? '').toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredFoodItems = tempList;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterFoodItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Theme.of(context).bottomAppBarTheme.color,
          elevation: 0,
          automaticallyImplyLeading: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          title: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () => _onCategorySelected(category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.defaultIconColor
                          : AppTheme.boxColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.green.withAlpha((255 * 0.3).toInt()),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for food...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: AppTheme.defaultIconColor,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Food list
          Expanded(
            child: _filteredFoodItems.isEmpty
                ? const Center(child: Text('No food items found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFoodItems.length,
                    itemBuilder: (context, index) {
                      final foodItem = _filteredFoodItems[index];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            foodItem['image_url'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          foodItem['name'],
                          style: const TextStyle(fontSize: 18),
                        ),
                        subtitle: Text(
                          'Category: ${foodItem['category']}',
                          style: const TextStyle(color: AppTheme.defaultIconColor),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.defaultIconColor,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AboutPage(
                                foodName: foodItem['name'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
