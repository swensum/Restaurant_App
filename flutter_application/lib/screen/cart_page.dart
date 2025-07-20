import 'package:flutter/material.dart';
import 'package:flutter_application/common/food_data.dart';
import 'package:flutter_application/common/provider.dart';
import 'package:flutter_application/screen/checkout.dart';
import 'package:flutter_application/theme.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    _loadFoodItems();
    
  }

  Future<void> _loadFoodItems() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        automaticallyImplyLeading: false,
        title: Text(
          'Cart',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (_, cartProvider, __) {
          final data = cartProvider.cartItems;
          return data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 64,
                        color: AppTheme.darkTheme().primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty!',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final foodItem = data[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: CartItem(
                              foodItem: foodItem,
                              onAdd: () {
                                cartProvider.incrementQuantity(foodItem);
                              },
                              onRemove: () {
                                // Check if quantity is 1, then remove the item
                                if (foodItem.quantity > 1) {
                                  cartProvider.decrementQuantity(foodItem);
                                } else {
                                  cartProvider.removeFromCart(foodItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${foodItem.name} removed from cart'),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Checkout(items: data),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkTheme().primaryColor,
                          foregroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: const Text('Checkout'),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}

class CartItem extends StatelessWidget {
  final FoodItem foodItem;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const CartItem({
    super.key,
    required this.foodItem,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = foodItem.price * foodItem.quantity;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.2).toInt()),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      margin: const EdgeInsets.all(8.0),
      child: ClipRRect(
        // Added ClipRRect to ensure all corners are rounded
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  // Changed from SizedBox to Container for better radius control
                  width: 80,
                  height: 95,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
                    image: foodItem.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(foodItem.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: foodItem.imageUrl.isEmpty
                      ? const Center(child: Icon(Icons.image, size: 60))
                      : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        8.0, 0.0, 0.0, 0.0), // Added padding to all sides
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodItem.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines:
                              1, // Prevent text from taking too much space
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Rs. ${foodItem.price}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.defaultIconColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon:  Icon(Icons.remove,
                                      size: 18, color: Theme.of(context).scaffoldBackgroundColor,),
                                  onPressed: onRemove,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Text(
                                  '${foodItem.quantity}',
                                  style:  TextStyle(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon:  Icon(Icons.add,
                                      size: 18, color: Theme.of(context).scaffoldBackgroundColor,),
                                  onPressed: onAdd,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((255 * 0.8).toInt()),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'Total : Rs.$totalPrice',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
