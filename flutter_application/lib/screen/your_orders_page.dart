import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      debugPrint("Fetching orders for user: $userId");
      
      final response = await Supabase.instance.client
          .from('orders_with_profiles')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint("Orders fetched: ${response.length}");
      if (response.isNotEmpty) {
        debugPrint("First order: ${response[0]}");
      }

      if (mounted) {
        setState(() {
          _orders = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e')),
      );
    }
  }

  String _getStatusStep(String status) {
    switch (status) {
      case "pending":
        return "Processing";
      case "confirmed":
        return "Preparing";
      case "dispatched":
        return "On the Way";
      case "delivered":
        return "Delivered";
      default:
        return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ?const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Text(
                        "No orders found",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final statusLabel = _getStatusStep(order['status']);
                      final createdAt = DateTime.parse(order['created_at']).toLocal();
                      final formattedDate =
                          '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

                      return Card(
                      color: Theme.of(context).bottomAppBarTheme.color,
                        margin: const EdgeInsets.all(8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Order #${order['id'].toString().substring(0, 8)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildOrderItems(order['items']),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Text(
                                    "Rs. ${order['total_price'].toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Payment: ${order['payment_method']}",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                             
                              const SizedBox(height: 12),
                              _buildTrackingStatus(statusLabel),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderItems(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Items:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map<Widget>((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    "• ${item['food_name']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    "Qty: ${item['quantity']}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTrackingStatus(String currentStatus) {
    final steps = ["Processing", "Preparing", "On the Way", "Delivered"];
    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Order Status:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: Stack(
            children: [
              Positioned(
                left: 15,
                top: 15,
                bottom: 15,
                child: Container(
                  width: 2,
                  color: Colors.grey.shade300,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: steps.map((step) {
                  final stepIndex = steps.indexOf(step);
                  final isDone = stepIndex <= currentIndex;
                  final isCurrent = stepIndex == currentIndex;

                  return Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isDone
                              ? isCurrent
                                  ? Colors.orange
                                  : Colors.green
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: isDone
                            ? Icon(
                                isCurrent ? Icons.timelapse : Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 70,
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrent ? FontWeight.bold : null,
                            color: isCurrent
                                ? Colors.orange
                                : isDone
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}