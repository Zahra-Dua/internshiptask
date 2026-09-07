// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'lab_staff/lab_staff_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Not logged in → Login screen
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Logged in but role abhi fetch ho raha hai
    if (auth.userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = auth.userModel!;

    // isActive false hone par access deny
    if (!user.isActive) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text('Your account has been deactivated.\nContact admin.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    // Role ke hisab se route
    if (user.isAdmin) {
      return const AdminDashboardScreen();
    } else {
      return const LabStaffDashboardScreen();
    }
  }
}
