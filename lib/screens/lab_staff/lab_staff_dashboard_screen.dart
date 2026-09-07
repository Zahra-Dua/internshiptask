// lib/screens/lab_staff/lab_staff_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'lab_staff_home_screen.dart';
import 'lab_staff_search_screen.dart';
import 'lab_staff_scan_screen.dart';
import 'lab_staff_history_screen.dart';
import 'lab_staff_profile_screen.dart';

class LabStaffDashboardScreen extends StatefulWidget {
  const LabStaffDashboardScreen({super.key});

  @override
  State<LabStaffDashboardScreen> createState() =>
      _LabStaffDashboardScreenState();
}

class _LabStaffDashboardScreenState extends State<LabStaffDashboardScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  int _selectedIndex = 0;

  final List<Widget> _tabs = const [
    LabStaffHomeScreen(),
    LabStaffSearchScreen(),
    LabStaffScanScreen(),
    LabStaffHistoryScreen(),
    LabStaffProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
