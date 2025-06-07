import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  final String selected;
  const AdminSidebar({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Text(
              'Admin Panel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildNavItem(context, 'Dashboard', '/admin', selected == 'dashboard'),
          _buildNavItem(context, 'Users', '/admin/users', selected == 'users'),
          _buildNavItem(context, 'Products', '/admin/menu', selected == 'products'),
          _buildNavItem(context, 'Categories', '/admin/categories', selected == 'categories'),
          _buildNavItem(context, 'Orders', '/admin/orders', selected == 'orders'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route, bool isSelected) {
    return ListTile(
      selected: isSelected,
      leading: _getIcon(title),
      title: Text(title),
      onTap: () {
        context.go(route);
      },
    );
  }

  Icon _getIcon(String title) {
    switch (title) {
      case 'Dashboard':
        return const Icon(Icons.dashboard);
      case 'Users':
        return const Icon(Icons.people);
      case 'Products':
        return const Icon(Icons.fastfood);
      case 'Categories':
        return const Icon(Icons.category);
      case 'Orders':
        return const Icon(Icons.receipt_long);
      default:
        return const Icon(Icons.circle);
    }
  }
} 