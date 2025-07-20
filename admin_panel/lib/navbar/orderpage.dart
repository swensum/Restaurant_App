import 'package:admin_panel/pages/mappage.dart';
import 'package:admin_panel/utils/supabase_clients.dart';
import 'package:admin_panel/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  RealtimeChannel? _ordersChannel;

  final List<String> statusOptions = [
    'preparing',
    'on the way',
    'delivered',
    'completed',
    'cancelled',
  ];

  final Map<String, String> localStatusOverrides = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _ordersChannel = Supabase.instance.client
        .channel('public:orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          callback: (payload) => _handleNewOrder(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (_) => _fetchOrders(),
        )
        .subscribe();
  }

  void _fetchOrders() {
    _ordersFuture = SupabaseService().fetchAllOrders();
    setState(() {});
  }

  void _handleNewOrder(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📦 New order received!"),
        backgroundColor: Colors.green,
      ),
    );
    _fetchOrders();
  }

  @override
  void dispose() {
    _ordersChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _updateStatus({
    required String orderId,
    required String userId,
    required String status,
  }) async {
    setState(() {
      localStatusOverrides[orderId] = status;
    });

    await SupabaseService().updateOrderStatus(orderId, status);
    await SupabaseService().notifyUserOrderStatus(
      userId: userId,
      status: status,
    );

    if (status == 'completed') {
      _ordersFuture = SupabaseService().fetchAllOrders();
      setState(() {});
    } else {
      _fetchOrders();
    }
  }

  String _formatDateTime(Object timestamp) {
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      final date = DateFormat('yyyy-MM-dd').format(dt);
      final time = DateFormat('HH:mm').format(dt);
      return "$date at $time";
    } catch (e) {
      return "Invalid date";
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'preparing':
        return Colors.orange;
      case 'on the way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusOption({
    required String orderId,
    required String currentStatus,
    required String newStatus,
    required VoidCallback onTap,
  }) {
    final isSelected = currentStatus == newStatus;
    final color = _getStatusColor(newStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        margin: const EdgeInsets.only(right: 10, bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(51),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Text(
          newStatus.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final orders = (snapshot.data ?? []).where((order) {
          return (localStatusOverrides[order['id']] ?? order['status']) != 'completed';
        }).toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("No active orders", style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final user = order['profiles'];
            final items = order['items'] as List<dynamic>;
            final orderId = order['id'] as String;
            final currentStatus = localStatusOverrides[orderId] ?? order['status'] ?? 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((255 * 0.5).toInt()),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).bottomAppBarTheme.color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ORDER #${orderId.substring(0, 8).toUpperCase()}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(order['created_at']),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(currentStatus).withAlpha((255 * 0.2).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(currentStatus),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Customer Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CUSTOMER",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?['username'] ?? 'Unknown Customer',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['shipping_address'] ?? 'No address provided',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  // Map Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminOrderMapPanel(userId: order['user_id']),
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on, color: Colors.red),
                          label: const Text("View Map", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),

                  // Items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ITEMS",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(item['food_name'] ?? 'Unknown Item')),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Qty: ${item['quantity']}",
                                      style: const TextStyle(color: AppTheme.defaultIconColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Total: Rs. ${order['total_price']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.defaultIconColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Payment: ${order['payment_method']}", style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),

                  // Status Options
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).bottomAppBarTheme.color,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 17),
                          child: Text(
                            "UPDATE STATUS",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: statusOptions.map((status) {
                              return _buildStatusOption(
                                orderId: orderId,
                                currentStatus: currentStatus,
                                newStatus: status,
                                onTap: () => _updateStatus(
                                  orderId: orderId,
                                  userId: order['user_id'],
                                  status: status,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
