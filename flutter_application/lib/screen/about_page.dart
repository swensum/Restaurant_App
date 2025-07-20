import 'package:flutter/material.dart';
import 'package:flutter_application/common/auth_service.dart';
import 'package:flutter_application/common/food_data.dart';
import 'package:flutter_application/common/provider.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/rating_utils.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AboutPage extends StatefulWidget {
  final String foodName;

  const AboutPage({super.key, required this.foodName});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late Future<List<Map<String, dynamic>>> _foodItems;
  Future<List<Map<String, dynamic>>>? _reviews;
  String? _currentUserName;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _foodItems = _supabaseService.getFoodItems();
    _fetchCurrentUser();
  }

  final AuthService _authService = AuthService();

  Future<void> _fetchCurrentUser() async {
    try {
      final userMap = await _authService.getCurrentUser();
      setState(() {
        _currentUserName = userMap['username'] ?? 'Guest';
      });
    } catch (e) {
      debugPrint('Error fetching username: $e');
      setState(() {
        _currentUserName = 'Guest';
      });
    }
  }

  // Call this after you get the foodItem ID to load reviews
  void _loadReviews(String foodId) {
    _reviews = _supabaseService.getReviews(foodId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _foodItems,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final foodItem = snapshot.data!.firstWhere(
          (item) => item['name'] == widget.foodName,
          orElse: () => {},
        );

        if (foodItem.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('Food item not found')));
        }

        // Load reviews only once when foodItem is ready
        if (_reviews == null) {
          _loadReviews(foodItem['id'].toString());
        }

        return Scaffold(
          backgroundColor: Theme.of(context).bottomAppBarTheme.color,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, foodItem),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildFoodDetails(context, foodItem),
                    ),
                  ),
                ],
              ),
              _buildBackButton(context),
              _buildBottomButtons(context, foodItem),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> foodItem) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              foodItem['image_url'],
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((255 * 0.6).toInt()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AverageRatingWidget(
                  reviewsFuture: _reviews!,
                  iconSize: 18,
                  iconColor: AppTheme.secondaryIconColor,
                  ratingTextStyle: TextStyle(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodDetails(BuildContext context, Map<String, dynamic> foodItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            foodItem['name'],
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.defaultIconColor,
                borderRadius: BorderRadius.only(topRight: Radius.circular(20)),
              ),
              child: Text(
                'Category: ${foodItem['category']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.defaultIconColor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
              ),
              child: Text(
                'Price: Rs. ${foodItem['price']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Description:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          foodItem['description'],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _buildReviewsHeader(foodItem),
        const SizedBox(height: 8),
        _buildReviewsList(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildReviewsHeader(Map<String, dynamic> foodItem) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reviews:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            setState(() {
              _reviews = _supabaseService.getReviews(foodItem['id'].toString());
            });
          },
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reviews,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!;
        if (reviews.isEmpty) {
          return const Text('No reviews yet. Be the first!');
        }

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final username = review['user_name'] ?? 'Anonymous';
              const avatarCount = 5;
              final avatarIndex = username.hashCode.abs() % avatarCount;
              final avatarPath = 'assets/avatar/image${avatarIndex + 1}.jpg';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 330),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                avatarPath,
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 30,
                                  height: 30,
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  child: const Icon(Icons.person, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                username,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: AppTheme.secondaryIconColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${review['rating']}',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            '"${review['comment']}"',
                            style: const TextStyle(
                              color: AppTheme.itemColor,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.itemColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: CircleAvatar(
        backgroundColor: AppTheme.defaultIconColor,
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).scaffoldBackgroundColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, Map<String, dynamic> foodItem) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Positioned(
     bottom: bottomPadding + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final cartProvider =
                    Provider.of<CartProvider>(context, listen: false);
                cartProvider.addToCart(FoodItem.fromMap(foodItem));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${foodItem['name']} added to cart')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.defaultIconColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              double rating = 0;
              final commentController = TextEditingController();

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Write a Review'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RatingBar.builder(
                          initialRating: 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          itemCount: 5,
                          itemSize: 30,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: AppTheme.secondaryIconColor,
                          ),
                          onRatingUpdate: (r) => rating = r,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Write your comment...',
                            hintStyle: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (rating == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select a rating')));
                            return;
                          }

                          try {
                            await _supabaseService.addReview(
                              foodId: foodItem['id'].toString(),
                              userName: _currentUserName ?? 'Guest',
                              rating: rating,
                              comment: commentController.text,
                            );

                            setState(() {
                              _reviews = _supabaseService
                                  .getReviews(foodItem['id'].toString());
                            });

                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to submit review: $e')));
                          }
                        },
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.defaultIconColor,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: Icon(
              Icons.rate_review,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
