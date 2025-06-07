import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_sidebar.dart';
import '../../providers/order_provider.dart';

class OrderManagement extends StatefulWidget {
  const OrderManagement({super.key});

  @override
  State<OrderManagement> createState() => _OrderManagementState();
}

class _OrderManagementState extends State<OrderManagement> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Order #${order['id']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order['user']?['name'] ?? 'N/A'}'),
                Text('Status: ${order['status']}'),
                const SizedBox(height: 8),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...((order['items'] as List?) ?? []).map((item) => Text('- ${item['product_name']} x${item['quantity']}')),
                const SizedBox(height: 8),
                Text('Total: \$${order['total']?.toStringAsFixed(2) ?? '0.00'}'),
                const SizedBox(height: 8),
                Text('Address: ${order['address'] ?? ''}'),
                Text('Phone: ${order['phone'] ?? ''}'),
                Text('Payment: ${order['payment_method'] ?? ''}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showStatusDialog(Map<String, dynamic> order) {
    final statusController = TextEditingController(text: order['status']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: DropdownButtonFormField<String>(
            value: statusController.text,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'processing', child: Text('Processing')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) => statusController.text = value ?? 'pending',
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                await orderProvider.updateOrderStatus(order['id'], statusController.text);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.orders;
    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      drawer: const AdminSidebar(selected: 'orders'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orders', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('No orders found.'))
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          title: Text('Order #${order['id']} - ${order['user']?['name'] ?? 'N/A'}'),
                          subtitle: Text('Status: ${order['status']} | Total: \$${order['total']?.toStringAsFixed(2) ?? '0.00'}'),
                          onTap: () => _showOrderDetailsDialog(order),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showStatusDialog(order),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Order'),
                                      content: const Text('Are you sure you want to delete this order?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await orderProvider.deleteOrder(order['id']);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 