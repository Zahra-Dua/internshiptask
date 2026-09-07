// lib/screens/lab_staff/lab_staff_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LabStaffDashboardScreen extends StatelessWidget {
  const LabStaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Staff Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, ${user.name} 👨‍🔧',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
