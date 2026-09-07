// lib/screens/lab_staff/lab_staff_scan_screen.dart
import 'package:flutter/material.dart';

class LabStaffScanScreen extends StatelessWidget {
  const LabStaffScanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Scan'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'QR/Barcode scanning coming soon.\nThis requires camera access setup.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
