import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'food_data.dart';

class CartProvider extends ChangeNotifier {
  final List<FoodItem> _cartItems = [];

  List<FoodItem> get cartItems => _cartItems;
  int get cartCount => _cartItems.fold(0, (total, item) => total + item.quantity);

  CartProvider() {
    _loadCartFromStorage();
  }

  Future<void> _saveCartToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = _cartItems.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('cartItems', cartJson);
  }

  Future<void> _loadCartFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('cartItems');

    if (jsonList != null && jsonList.isNotEmpty) {
      _cartItems.clear();
      _cartItems.addAll(jsonList.map((e) => FoodItem.fromJson(json.decode(e))));
    }

    notifyListeners();
  }

  void addToCart(FoodItem item) {
    final index = _cartItems.indexWhere((cartItem) => cartItem.id == item.id);
    if (index >= 0) {
      _cartItems[index].incrementQuantity();
    } else {
      _cartItems.add(item);
    }
    _saveCartToStorage();
    notifyListeners();
  }

  void removeFromCart(FoodItem item) {
    _cartItems.removeWhere((i) => i.id == item.id);
    _saveCartToStorage();
    notifyListeners();
  }

  void incrementQuantity(FoodItem item) {
    item.incrementQuantity();
    _saveCartToStorage();
    notifyListeners();
  }

  void decrementQuantity(FoodItem item) {
    if (item.quantity > 1) {
      item.decrementQuantity();
    } else {
      _cartItems.removeWhere((i) => i.id == item.id);
    }
    _saveCartToStorage();
    notifyListeners();
  }
}
