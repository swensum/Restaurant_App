import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/theme.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await _supabaseService.getAllReviews();
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reviews.';
        _isLoading = false;
      });
    }
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final username = review['user_name'] ?? 'Anonymous';
final foodName = review['food_name'] ?? 'Unknown Food';
final rating = (review['rating'] ?? 0).toDouble();
final comment = review['comment'] ?? '';
final date = review['date'] ?? '';

    // Logic to select avatar image based on username hash
    const int avatarCount = 5;
    int avatarIndex = 0;
    if (username.isNotEmpty) {
      avatarIndex = username.hashCode.abs() % avatarCount;
    }
    final avatarPath = 'assets/avatar/image${avatarIndex + 1}.jpg';

    return Card(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: Image.asset(
            avatarPath,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 48,
              height: 48,
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 30, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($foodName)',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('($rating)',
                      style:const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.defaultIconColor,
                      )),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"$comment"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600], // slightly dimmed grey color
                ),
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
         backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        title: const Text('All User Reviews'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _reviews.isEmpty
                  ? const Center(child: Text('No reviews found.'))
                  : RefreshIndicator(
                      onRefresh: _fetchReviews,
                      child: ListView.builder(
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewItem(_reviews[index]);
                        },
                      ),
                    ),
    );
  }
}
