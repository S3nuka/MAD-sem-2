import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mad/screens/auth/login_screen.dart';
import 'package:mad/screens/auth/register_screen.dart';
import 'package:mad/screens/home_screen.dart';
import 'package:mad/screens/menu_screen.dart';
import 'package:mad/screens/cart_screen.dart';
import 'package:mad/screens/profile_screen.dart';
import 'package:mad/screens/device_info_screen.dart';
import 'package:mad/screens/admin/admin_dashboard.dart';
import 'package:mad/screens/admin/user_management.dart';
import 'package:mad/screens/admin/menu_management.dart';
import 'package:mad/screens/admin/order_management.dart';
import 'package:mad/screens/checkout_screen.dart';
import 'package:mad/config/theme.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'providers/device_provider.dart';
import 'providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Initializing App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // User routes
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/device-info',
      builder: (context, state) => const DeviceInfoScreen(),
    ),
    
    // Admin routes
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const UserManagement(),
    ),
    GoRoute(
      path: '/admin/menu',
      builder: (context, state) => const MenuManagement(),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const OrderManagement(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
  ],
  redirect: (context, state) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isAdminRoute = state.matchedLocation.startsWith('/admin');

    // Show loading indicator while checking auth status
    if (authProvider.isLoading) {
      return null;
    }

    // Handle authentication errors
    if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication error: ${authProvider.error}'),
          backgroundColor: Colors.red,
    ),
      );
      return '/login';
    }

    // Check if user is logged in
    if (!authProvider.isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    // Redirect logged-in users away from auth routes
    if (authProvider.isAuthenticated && isAuthRoute) {
      return authProvider.isAdmin ? '/admin' : '/';
    }

    // Check admin access for admin routes
    if (isAdminRoute && !authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );
      return '/';
    }

    return null;
  },
);

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Food Ordering App',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.useSystemTheme
                ? ThemeMode.system
                : themeProvider.isDarkMode
                    ? ThemeMode.dark
                    : ThemeMode.light,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
