// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:internshiptask/widgets/stock_notification_watcher.dart';
import 'dashboard_home_screen.dart';
import 'component_list_screen.dart';
import 'manage_staff_screen.dart';
import 'transactions_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    DashboardHomeScreen(),
    ComponentListScreen(),
    ManageStaffScreen(),
    TransactionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StockNotificationWatcher(
        child: IndexedStack(index: _selectedIndex, children: _tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Manage Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
