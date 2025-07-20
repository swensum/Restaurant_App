import 'package:flutter/material.dart';
import 'package:flutter_application/supabase_client.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:flutter_application/theme.dart';

class PaypalPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final SupabaseService supabaseService;

  const PaypalPaymentScreen({
    super.key,
    required this.totalAmount,
     required this.supabaseService,
  });

  @override
  State<PaypalPaymentScreen> createState() => _PaypalPaymentScreenState();
}

class _PaypalPaymentScreenState extends State<PaypalPaymentScreen> {
  bool _isLoading = true; // Start in loading state

  @override
  void initState() {
    super.initState();
    // Automatically start payment when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPayPalPayment(context);
    });
  }

  Future<void> _startPayPalPayment(BuildContext context) async {
    try {
      final config = await widget.supabaseService.getPaypalConfig();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaypalCheckoutView(
            sandboxMode: config['sandboxMode'],
            clientId: config['clientId'],
            secretKey: config['secretKey'],
            transactions: [
              {
                "amount": {
                  "total": widget.totalAmount.toString(),
                  "currency": "USD",
                  "details": {
                    "subtotal": widget.totalAmount.toString(),
                    "shipping": "0",
                    "shipping_discount": "0",
                  },
                },
                "description": "Order payment",
              },
            ],
            note: "Contact us for any questions on your order.",
            onSuccess: (Map params) => _showSuccessMessage(context),
            onError: (error) {
              Navigator.of(context).pop(); // Close PayPal screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment failed, please try again later.'),
                ),
              );
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      Navigator.of(context).pop(); // Close this screen if error occurs
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Processing PayPal Payment"),
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    "Connecting to PayPal...",
                    style: TextStyle(
                      color: AppTheme.darkTheme().primaryColor,
                    ),
                  ),
                ],
              )
            : const SizedBox(), // Empty when not loading
      ),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Payment Successful"),
          content: const Text("Thank you for your purchase!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}