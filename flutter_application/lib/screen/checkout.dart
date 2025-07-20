import 'package:flutter/material.dart';
import 'package:flutter_application/common/food_data.dart';
import 'package:flutter_application/common/mapscreen.dart';
import 'package:flutter_application/screen/your_orders_page.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_application/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Checkout extends StatefulWidget {
  final List<FoodItem> items;

  const Checkout({super.key, required this.items});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  String _selectedPaymentMethod = "Please select a method";
  String _shippingAddress = "(for eg:Manigram-08,tilottama, rupandehi)";

  @override
  Widget build(BuildContext context) {
    final double grossPrice =
        widget.items.fold(0, (sum, item) => sum + item.price * item.quantity);
    const double discount = 0.0;
    const deliveryCharge = 5.0;
    final double totalPrice = grossPrice - discount + deliveryCharge;

    return Scaffold(
      backgroundColor: Theme.of(context).bottomAppBarTheme.color,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        automaticallyImplyLeading: false,
        title: Text(
          "Checkout",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            tooltip: "Back",
            icon: Icon(
              Icons.clear,
              color: AppTheme.darkTheme().primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey, // Assign form key here
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Shipping Address",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      IconButton(
                        onPressed: () async {
                          final selectedAddress = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MapScreen()),
                          );
                          if (selectedAddress != null) {
                            setState(() {
                              _shippingAddress = selectedAddress;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: Text(
                    "Customer Address",
                    style: TextStyle(
                      color: AppTheme.darkTheme().primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    _shippingAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 10.0),
                const Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Text("Payment Method"),
                ),
                FormField<String>(
                  initialValue: _selectedPaymentMethod,
                  validator: (value) {
                    if (value == null || value == "Please select a method") {
                      return "Please select a payment method";
                    }
                    return null;
                  },
                  builder: (fieldState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2.0,
                          child: ListTile(
                            title: Text(
                              _selectedPaymentMethod,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            leading: Image.asset(
                              'assets/payment.png',
                              width: 24,
                              height: 24,
                            ),
                            trailing: PopupMenuButton<String>(
                              offset: const Offset(0, 55),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: AppTheme.darkTheme().primaryColor,
                              ),
                              onSelected: (String newValue) {
                                setState(() {
                                  _selectedPaymentMethod = newValue;
                                  fieldState.didChange(newValue);
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  _paymentMethodItem('PayPal', 'assets/esewa.png'),
                                  _paymentMethodItem('Khalti', 'assets/khalti.png'),
                                  _paymentMethodItem('Cash on Delivery', 'assets/cash.png'),
                                  PopupMenuItem(
                                    value: 'Credit Card',
                                    child: ListTile(
                                      leading: Icon(
                                        FontAwesomeIcons.creditCard,
                                        color: AppTheme.darkTheme().primaryColor,
                                      ),
                                      title: Text(
                                        'Credit Card',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        ),
                        if (fieldState.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                            child: Text(
                              fieldState.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10.0),
                const Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: Text("Items"),
                ),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.2).toInt()),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final foodItem = widget.items[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: foodItem.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                foodItem.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              'Rs. ${(foodItem.price * foodItem.quantity).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Quantity: ${foodItem.quantity}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        height: 230,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((255 * 0.8).toInt()),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((255 * 0.5).toInt()),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gross Price:'),
                        Text(
                          'Rs. ${grossPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:'),
                        Text(
                          'Rs. 0.00',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Charge:'),
                        Text(
                          'Rs. ${deliveryCharge.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs. ${totalPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                        AppTheme.darkTheme().primaryColor),
                    foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      // Payment method validation failed
                      return;
                    }

                    if (_shippingAddress ==
                        "(for eg:Manigram-08,tilottama, rupandehi)") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please fill out the shipping address.')),
                      );
                      return;
                    }

                    if (_selectedPaymentMethod == "PayPal") {
                      // Your existing PayPal flow...
                    } else {
                      try {
                        final supabaseService = SupabaseService();

                        // Prepare your order data
                        final orderData = {
                          'user_id': Supabase.instance.client.auth.currentUser?.id,
                          'items': widget.items
                              .map((item) => {
                                    'food_name': item.name,
                                    'quantity': item.quantity,
                                  })
                              .toList(),
                          'total_price': totalPrice,
                          'payment_method': _selectedPaymentMethod,
                          'shipping_address': _shippingAddress,
                          'status': 'pending',
                          'created_at': DateTime.now().toUtc().toIso8601String(),
                        };

                        // Place the order
                        await supabaseService.placeOrder(orderData);
                        final user = Supabase.instance.client.auth.currentUser;
                        await supabaseService.notifyAdminsNewOrder(
                            user?.email ?? "a customer");

                        _showSuccessMessage();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to place order: $e')),
                        );
                      }
                    }
                  },
                  child: const Text("PLACE ORDER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _paymentMethodItem(String title, String assetPath) {
    return PopupMenuItem(
      value: title,
      child: ListTile(
        leading: Image.asset(
          assetPath,
          width: 24,
          height: 24,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Order Placed"),
        content:
            const Text("Thank you for choosing us! Your order has been placed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersPage()),
              );
            },
            child: const Text("View Orders"),
          )
        ],
      ),
    );
  }
}
