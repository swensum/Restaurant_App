import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String name;
  final String imageUrl;
  final double rating;

  FavoriteItem({
    required this.name,
    required this.imageUrl,
    required this.rating,
  });
   Map<String, dynamic> toJson() => {
        'name': name,
        'imageUrl': imageUrl,
        'rating': rating,
      };
       factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        name: json['name'],
        imageUrl: json['imageUrl'],
        rating: (json['rating'] as num).toDouble(),
      );
}

class FavoriteProvider extends ChangeNotifier {
  final List<FavoriteItem> _favoriteItems = [];

  // Getter to retrieve the list of favorite items
  List<FavoriteItem> get favoriteItems => _favoriteItems;

  // Getter to retrieve the count of favorite items
  int get favoritesCount => _favoriteItems.length;
   FavoriteProvider() {
    _loadFavorites();
  }
   Future<void> _loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('favorites');
    if (jsonList != null) {
      _favoriteItems.clear();
      _favoriteItems.addAll(jsonList.map((e) => FavoriteItem.fromJson(json.decode(e))));
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _favoriteItems.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('favorites', jsonList);
  }

  void addToFavorites(FavoriteItem item) {
    _favoriteItems.add(item);
    _saveFavorites();
    notifyListeners();
  }

  void removeFromFavorites(FavoriteItem item) {
    _favoriteItems.removeWhere((e) => e.name == item.name);
    _saveFavorites();
    notifyListeners();
  }
}
