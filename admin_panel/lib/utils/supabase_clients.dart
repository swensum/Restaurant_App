// lib/services/supabase_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  

  // ✅ Get all food items
  Future<List<Map<String, dynamic>>> getFoodItems() async {
    try {
      final response = await _supabase
          .from('food')
          .select('*')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response).map((item) {
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
    } catch (e) {
      debugPrint('Error fetching food items: $e');
      return [];
    }
  }

  // ✅ Get reviews for a specific food item
  Future<List<Map<String, dynamic>>> getReviews(String foodId) async {
    try {
      final response = await _supabase
          .from('review')
          .select('*')
          .eq('food_id', foodId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((review) {
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

  // ✅ Get all reviews (with food name) — good for a Reviews section in admin panel
  Future<List<Map<String, dynamic>>> getAllReviews() async {
    try {
      final response = await _supabase
          .from('review')
          .select('id, user_name, rating, comment, created_at, food:food_id(name)')
          .order('created_at', ascending: false);

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
   Future<List<Map<String, dynamic>>> fetchAllOrders() async {
  final response = await _supabase
      .from('orders')
      .select('id, user_id, items, total_price, payment_method, shipping_address, status, created_at, profiles (username, email)')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
}

 Future<void> notifyUserOrderStatus({
  required String userId,
  required String status,
}) async {
  try {
    final response = await _supabase
        .from('user_tokens')
        .select('fcm_token')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null || response['fcm_token'] == null) {
      debugPrint("❌ No FCM token found for user $userId");
      return;
    }

    final token = response['fcm_token'];

    final url = Uri.parse(
      'https://hydrecojpufsqnzpfqjp.functions.supabase.co/send-push',
    );

    final statusMessage = {
      'preparing': 'Your order is being prepared 🧑‍🍳',
      'on the way': 'Your order is on the way 🚚',
      'delivered': 'Your order has been delivered 🎉',
      'cancelled': 'Your order has been cancelled ❌',
    }[status] ?? 'Order status updated';

    final body = jsonEncode({
      'token': token,
      'title': '📦 Order Update',
      'body': statusMessage,
    });

    final pushRes = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (pushRes.statusCode == 200) {
      debugPrint("✅ Push sent to $userId: $statusMessage");
    } else {
      debugPrint("❌ Push failed: ${pushRes.body}");
    }
  } catch (e) {
    debugPrint("❌ Error notifying user: $e");
  }
}

Future<void> updateOrderStatus(String orderId, String status) async {
  try {
    await _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);

    debugPrint('✅ Order $orderId updated to "$status"');
  } catch (e) {
    debugPrint('❌ Failed to update order status: $e');
    rethrow;
  }
}




  Future<void> saveAdminTokenToDB(String token) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('No logged in admin user found');
    return;
  }

  try {
    final response = await _supabase.from('admin_tokens').upsert(
      {
        'admin_id': userId,
        'fcm_token': token,
      },
      onConflict: 'admin_id',
    );

    if (response.error != null) {
      debugPrint('Failed to save admin token: ${response.error!.message}');
    } else {
      debugPrint('Admin token saved successfully');
    }
  } catch (e) {
    debugPrint('Exception saving admin token: $e');
  }
}


Future<List<Map<String, dynamic>>> fetchCompletedOrders() async {
  final response = await _supabase
      .from('orders')
      .select('id, user_id, items, total_price, payment_method, shipping_address, status, created_at, profiles (username, email)')
      .eq('status', 'completed')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
}

Future<List<String>> fetchCategories() async {
  try {
    final response = await _supabase.from('categories').select('name');
    return List<String>.from(response.map((e) => e['name'].toString()));
  } catch (e) {
    debugPrint('❌ Error fetching categories: $e');
    return [];
  }
}
Future<bool> addCategory(String name) async {
  try {
    final exists = await _supabase
        .from('categories')
        .select('id')
        .eq('name', name)
        .maybeSingle();

    if (exists != null) {
      debugPrint('⚠️ Category already exists');
      return false;
    }

    await _supabase.from('categories').insert({'name': name});
    debugPrint('✅ Category "$name" added');
    return true;
  } catch (e) {
    debugPrint('❌ Error adding category: $e');
    return false;
  }
}



Future<bool> updateFoodItem(String id, Map<String, dynamic> data) async {
  try {
    final response = await _supabase
        .from('food')
        .update(data)
        .eq('id', id)
        .select(); 

    if (response.isEmpty) {
      debugPrint("❌ No rows updated. Possible wrong ID or RLS restriction.");
      return false;
    }

    debugPrint("✅ Updated food item: ${response.first}");
    return true;
  } catch (e) {
    debugPrint("❌ Error updating food item: $e");
    return false;
  }
}


Future<String?> uploadImageFile(File file, String fileName, String contentType) async {
  try {
    final storage = _supabase.storage.from('restaurant.menu'); // Correct bucket name here
    final filePath = fileName;   

    await storage.uploadBinary(
      filePath,
      await file.readAsBytes(),
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    return storage.getPublicUrl(filePath);
  } catch (e) {
    debugPrint('❌ Upload error: $e');
    return null;
  }
}
Future<bool> deleteImageByUrl(String imageUrl) async {
  try {
    final uri = Uri.parse(imageUrl);
    final segments = uri.pathSegments;

    // Make sure it's a Supabase Storage public URL
    const bucket = 'restaurant.menu';
    final bucketIndex = segments.indexOf(bucket);

    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
      debugPrint("❌ Invalid image URL format: $imageUrl");
      return false;
    }

    final filePath = segments.sublist(bucketIndex + 1).join('/');

    debugPrint("🗑️ Deleting file from bucket \"$bucket\" with path \"$filePath\"");

    await _supabase.storage.from(bucket).remove([filePath]);

    debugPrint("✅ Deleted image successfully");
    return true;
  } catch (e) {
    debugPrint("❌ Delete image failed: $e");
    return false;
  }
}


}
