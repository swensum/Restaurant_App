import 'package:flutter/material.dart';

class FoodItem extends ChangeNotifier {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool availability;
  final String imageUrl;
  final double? rating;
  int quantity;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.availability,
    required this.imageUrl,
    this.rating,
    this.quantity = 1,
  });

  void incrementQuantity() {
    quantity += 1;
    notifyListeners();
  }

  void decrementQuantity() {
    if (quantity > 0) {
      quantity -= 1;
      notifyListeners();
    }
  }

  // ✅ Use this in your app where you call FoodItem.fromMap (Appwrite/Supabase)
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] is num
          ? (map['price'] as num).toDouble()
          : double.parse(map['price'].toString())),
      category: map['category'] as String,
      availability: map['availability'] as bool,
      imageUrl: map['image_url'] as String,
      rating: map['rating'] != null
          ? (map['rating'] is num
              ? (map['rating'] as num).toDouble()
              : double.parse(map['rating'].toString()))
          : null,
    );
  }

  // ✅ Use this in CartProvider for saving to SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'availability': availability,
        'image_url': imageUrl,
        'rating': rating,
        'quantity': quantity,
      };

  // ✅ Use this in CartProvider for reading from SharedPreferences
  factory FoodItem.fromJson(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] is num
          ? map['price'].toDouble()
          : double.parse(map['price'].toString())),
      category: map['category'] as String,
      availability: map['availability'] as bool,
      imageUrl: map['image_url'] as String,
      rating: map['rating'] != null
          ? (map['rating'] is num
              ? map['rating'].toDouble()
              : double.parse(map['rating'].toString()))
          : null,
      quantity: map['quantity'] ?? 1,
    );
  }

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, quantity: $quantity)';
  }
}
