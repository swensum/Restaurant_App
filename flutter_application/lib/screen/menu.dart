import 'package:flutter/material.dart';
import 'package:flutter_application/homescreen.dart';
import 'package:flutter_application/screen/popular_item.dart';
import 'package:flutter_application/ui/food_categories.dart';
import 'package:flutter_application/ui/search_page.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
         backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        automaticallyImplyLeading: false,
        title: Row(
          
          children: [
            
            Image.asset(
              'assets/hamburger.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8.0),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: <Color>[
                    Color(0xFF09203F),
                    Color(0xFF537895),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds);
              },
              child: const Text(
                ' Grand Kitchen',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              ),
            ),
          ],
        ),
        
       actions: [
        Padding(
    padding: const EdgeInsets.only(right: 7.0),
    child: Icon(
     Icons.notifications,
      color: Theme.of(context).iconTheme.color,
      size: 28.0,
    ),
  ),

  Padding(
    padding: const EdgeInsets.only(right: 10.0), // Adjust to move left
    child: IconButton(
      icon: Icon(
        Icons.search,
        color: Theme.of(context).iconTheme.color,
        size: 30.0, // Increased size
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        );
      },
    ),
  ),
],
      ),

      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DishesLayout(),
              SizedBox(height: 20),
              FoodCategories(),
              PopularItemsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
