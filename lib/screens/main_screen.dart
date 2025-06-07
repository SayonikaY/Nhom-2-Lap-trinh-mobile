import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/sales_summary_dialog.dart';
import 'login_screen.dart';
import 'menu/menu_items_screen.dart';
import 'orders/orders_screen.dart';
import 'tables/tables_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TablesScreen(),
    const MenuItemsScreen(),
    const OrdersScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    try {
      // Show loading dialog while fetching sales summary
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Loading sales summary...'),
                ],
              ),
            ),
      );

      // Fetch today's sales summary
      final salesResponse = await AuthService.getSalesSummary();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (salesResponse.success && salesResponse.data != null) {
        // Show sales summary dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => SalesSummaryDialog(
                  salesSummary: salesResponse.data!,
                  onConfirmLogout: _performLogout,
                ),
          );
        }
      } else {
        // If sales summary fails, show simple confirmation dialog
        if (mounted) {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load sales summary.'),
                      const SizedBox(height: 8),
                      const Text('Are you sure you want to logout?'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
          );

          if (shouldLogout == true) {
            _performLogout();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open

        // Show error and simple confirmation
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Logout'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Error loading sales summary.'),
                    const SizedBox(height: 8),
                    const Text('Are you sure you want to logout?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
        );

        if (shouldLogout == true) {
          _performLogout();
        }
      }
    }
  }

  Future<void> _performLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Tables',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
