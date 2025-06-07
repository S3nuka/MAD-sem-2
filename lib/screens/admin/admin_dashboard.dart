import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_sidebar.dart';
import '../../providers/user_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
      Provider.of<MenuProvider>(context, listen: false).loadProducts();
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    final totalUsers = userProvider.users.length;
    final totalProducts = menuProvider.products.length;
    final totalOrders = orderProvider.orders.length;
    final recentOrders = orderProvider.orders.take(5).toList();

    return Scaffold(
      drawer: const AdminSidebar(selected: 'dashboard'),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Users', totalUsers.toString(), Icons.people, Colors.blue),
                _buildStatCard('Products', totalProducts.toString(), Icons.fastfood, Colors.orange),
                _buildStatCard('Orders', totalOrders.toString(), Icons.receipt_long, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: recentOrders.isEmpty
                  ? const Text('No recent orders.')
                  : ListView.builder(
                      itemCount: recentOrders.length,
                      itemBuilder: (context, index) {
                        final order = recentOrders[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(order['id'].toString()),
                            ),
                            title: Text('Order #${order['id']}'),
                            subtitle: Text('Total: ${order['total']?.toStringAsFixed(2) ?? '0.00'}'),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
} 