// lib/screens/lab_staff/lab_staff_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';
import 'lab_staff_search_screen.dart';
import '../image_search_screen.dart';

class LabStaffHomeScreen extends StatefulWidget {
  const LabStaffHomeScreen({super.key});

  @override
  State<LabStaffHomeScreen> createState() => _LabStaffHomeScreenState();
}

class _LabStaffHomeScreenState extends State<LabStaffHomeScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _searchController = TextEditingController();

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature — coming soon')));
  }

  void _goToSearch([String query = '']) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabStaffSearchScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final componentService = ComponentService();
    final inventoryService = InventoryService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Good day, ${user?.name ?? 'there'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'What component are you looking for?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code or part no.',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (val) => _goToSearch(val),
            ),
            const SizedBox(height: 12),

            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImageSearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search by Image',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Scan a component photo',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _quickTile(
                    icon: Icons.qr_code_2,
                    color: Colors.orange,
                    title: 'Scan QR',
                    subtitle: 'Component / Bin QR',
                    onTap: () => _comingSoon('QR Scanning'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickTile(
                    icon: Icons.history,
                    color: Colors.green,
                    title: 'Transactions',
                    subtitle: 'Issued / returned',
                    onTap: () => _comingSoon('Transaction history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENTLY USED',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton(
                  onPressed: () => _comingSoon('Recently used tracking'),
                  child: const Text('See All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No recently used components yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'AVAILABILITY ALERTS',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<ComponentModel>>(
              stream: componentService.getComponents(),
              builder: (context, compSnap) {
                final components = compSnap.data ?? [];
                return StreamBuilder<List<InventoryModel>>(
                  stream: inventoryService.getAllInventory(),
                  builder: (context, invSnap) {
                    final inventory = invSnap.data ?? [];
                    final qtyMap = <String, int>{};
                    for (var rec in inventory) {
                      qtyMap[rec.componentId] =
                          (qtyMap[rec.componentId] ?? 0) + rec.quantity;
                    }

                    final alerts = components
                        .where((c) {
                          final q = qtyMap[c.id] ?? 0;
                          return q <= c.minimumStock;
                        })
                        .take(3)
                        .toList();

                    if (alerts.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'All components are sufficiently stocked.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }

                    return Column(
                      children: alerts.map((c) {
                        final q = qtyMap[c.id] ?? 0;
                        final isOut = q == 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${c.name} is ${isOut ? "Out of Stock" : "Low on Stock"}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      isOut
                                          ? 'No units currently available.'
                                          : 'Only $q left (min ${c.minimumStock}).',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
