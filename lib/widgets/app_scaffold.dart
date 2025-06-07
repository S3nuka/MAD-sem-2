import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  final String title;
  final bool showNavBar;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.child,
    required this.title,
    this.showNavBar = true,
    this.actions,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        actions: widget.actions,
      ),
      body: widget.child,
      bottomNavigationBar: widget.showNavBar ? Builder(
        builder: (context) {
          final path = GoRouterState.of(context).uri.path;
          final selectedIndex = switch (path) {
            '/' => 0,
            '/menu' => 1,
            '/cart' => 2,
            '/profile' => 3,
            _ => 0,
          };

          return NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/');
                  break;
                case 1:
                  context.go('/menu');
                  break;
                case 2:
                  context.go('/cart');
                  break;
                case 3:
                  context.go('/profile');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Menu',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        }
      ) : null,
    );
  }
}
