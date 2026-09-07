// lib/screens/lab_staff/lab_staff_history_screen.dart
import 'package:flutter/material.dart';

class LabStaffHistoryScreen extends StatelessWidget {
  const LabStaffHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Transaction history coming soon.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
