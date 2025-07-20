// lib/services/supabase_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SupabaseService {
  // Get the Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;
   SupabaseClient get client => _supabase;

 Future<List<Map<String, dynamic>>> getFoodItems() async {
  try {
    debugPrint('Fetching food items from Supabase...');
    final response = await _supabase
        .from('food')
        .select('*')
        .order('name', ascending: true);

    debugPrint('Raw response from Supabase: $response');

    final items = List<Map<String, dynamic>>.from(response).map((item) {
      return {
        'id': item['id'] ?? '',
        'name': item['name'] ?? 'Unknown',
        'description': item['description'] ?? 'No description',
        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
        'category': item['category'] ?? 'Uncategorized',
        'availability': item['availability'] ?? false,
        'image_url': item['image_url'] ?? '',
        'rating': (item['rating'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    debugPrint('Processed ${items.length} food items');
    return items;
  } catch (e) {
    debugPrint('Error fetching food items: $e');
    return [];
  }
}




 Future<List<Map<String, dynamic>>> getReviews(String foodId) async {
  try {
    final response = await _supabase
        .from('review')
        .select('*')
        .eq('food_id', foodId)
        .order('created_at', ascending: false);

    if (response.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response).map((review) {
      // Handle date formatting safely
      String formattedDate = 'No date';
      try {
        if (review['created_at'] != null) {
          formattedDate = DateFormat('MMM dd, yyyy')
              .format(DateTime.parse(review['created_at']).toLocal());
        }
      } catch (e) {
        debugPrint('Error formatting date: $e');
      }

      return {
        'id': review['id']?.toString() ?? '',
        'user_name': review['user_name']?.toString() ?? 'Anonymous',
        'rating': (review['rating'] as num?)?.toDouble() ?? 0.0,
        'comment': review['comment']?.toString() ?? '',
        'date': formattedDate,
      };
    }).toList();
  } catch (e) {
    debugPrint('Error fetching reviews: $e');
    return [];
  }
}



  Future<void> addReview({
  required String foodId,
  required String userName,
  required double rating,
  required String comment,
}) async {
  try {
    await _supabase.from('review').insert({
      'food_id': foodId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      
    });
  } catch (e) {
    debugPrint('Error adding review: $e');
    rethrow;
  }
}


Future<List<Map<String, dynamic>>> getAllReviews() async {
  try {
    final response = await _supabase
        .from('review')
        .select('id, user_name, rating, comment, created_at, food:food_id(name)')
        .order('created_at', ascending: false);

    if (response.isEmpty) {
      return [];
    }

    return List<Map<String, dynamic>>.from(response).map((review) {
      String formattedDate = 'No date';
      try {
        if (review['created_at'] != null) {
          formattedDate = DateFormat('MMM dd, yyyy')
              .format(DateTime.parse(review['created_at']).toLocal());
        }
      } catch (e) {
        debugPrint('Date format error: $e');
      }

      return {
        'id': review['id']?.toString() ?? '',
        'user_name': review['user_name'] ?? 'Anonymous',
        'rating': (review['rating'] as num?)?.toDouble() ?? 0.0,
        'comment': review['comment'] ?? '',
        'date': formattedDate,
        'food_name': review['food']?['name'] ?? 'Unknown Food',
      };
    }).toList();
  } catch (e) {
    debugPrint('Error fetching reviews: $e');
    return [];
  }
}


Future<void> placeOrder(Map<String, dynamic> orderData) async {
  try {
    await _supabase.from('orders').insert(orderData);
  } catch (e) {
    debugPrint('Error placing order: $e');
    rethrow;
  }
}


Future<void> notifyAdminsNewOrder(String customerName) async {
  try {
    final List<dynamic> data = await _supabase
        .from('admin_tokens')
        .select('fcm_token');

    if (data.isEmpty) {
      debugPrint('No admin tokens available');
      return;
    }

    final tokens = data.map((e) => e['fcm_token'] as String).toList();

    final url = Uri.parse(
      'https://hydrecojpufsqnzpfqjp.functions.supabase.co/send-push',
    );

    final body = jsonEncode({
      'tokens': tokens,
      'title': '🛒 New Order Received',
      'body': 'You have a new order from $customerName',
    });

    final pushResponse = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (pushResponse.statusCode == 200) {
      debugPrint('Admin notified successfully');
    } else {
      debugPrint('Failed to notify admin: ${pushResponse.body}');
    }
  } catch (e) {
    debugPrint('Error notifying admins: $e');
  }
}

  Future<Map<String, dynamic>> getPaypalConfig() async {
    try {
      final response = await _supabase
          .from('payment_keys')
          .select('*')
          .single();

      return {
        'clientId': response['paypal_client_id'] ?? '',
        'secretKey': response['paypal_secret_key'] ?? '',
        'sandboxMode': response['sandbox_mode'] ?? true,
      };
    } catch (e) {
      throw Exception('Failed to fetch PayPal config: $e');
    }
  }
  Future<List<Map<String, dynamic>>> getFoodItemsByCategory(String categoryName) async {
  try {
    final response = await _supabase
        .from('food')
        .select()
        .eq('category', categoryName);

    // response is usually List<dynamic>, so convert to List<Map<String, dynamic>>
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    // Handle or rethrow exception
    throw Exception('Failed to fetch food items: $e');
  }
}


}