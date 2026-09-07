// lib/screens/admin/dashboard_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final componentService = ComponentService();
    final inventoryService = InventoryService();
    final currentUser = context.watch<AuthProvider>().userModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: StreamBuilder<List<ComponentModel>>(
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

                final totalUnits = inventory.fold<int>(
                  0,
                  (sum, r) => sum + r.quantity,
                );

                final lowStock = components.where((c) {
                  final q = qtyMap[c.id] ?? 0;
                  return q > 0 && q <= c.minimumStock;
                }).toList();

                final outOfStock = components
                    .where((c) => (qtyMap[c.id] ?? 0) == 0)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          child: Text(
                            currentUser != null && currentUser.name.isNotEmpty
                                ? currentUser.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Good day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                currentUser?.name ?? 'Admin',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.grey),
                          onPressed: () =>
                              context.read<AuthProvider>().logout(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _statCard(
                          Icons.memory,
                          'Total Components',
                          '${components.length}',
                          primaryColor,
                        ),
                        _statCard(
                          Icons.inventory_2_outlined,
                          'Total Units',
                          '$totalUnits',
                          Colors.blue,
                        ),
                        _statCard(
                          Icons.warning_amber_rounded,
                          'Low Stock',
                          '${lowStock.length}',
                          Colors.orange,
                        ),
                        _statCard(
                          Icons.error_outline,
                          'Out of Stock',
                          '${outOfStock.length}',
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Low Stock',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (lowStock.isEmpty && outOfStock.isEmpty)
                      _emptyCard(
                        'No low stock or out-of-stock items right now.',
                      )
                    else
                      ...[...outOfStock, ...lowStock].take(5).map((c) {
                        final qty = qtyMap[c.id] ?? 0;
                        final isOut = qty == 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOut
                                    ? Icons.remove_circle_outline
                                    : Icons.warning_amber,
                                color: isOut ? Colors.red : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      c.componentCode,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (isOut ? Colors.red : Colors.orange)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isOut
                                      ? 'OUT'
                                      : 'LOW ($qty/${c.minimumStock})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOut ? Colors.red : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                    const Text(
                      'Most Used Components',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _emptyCard(
                      'Usage tracking will appear here once transactions are enabled.',
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _emptyCard('No recent activity yet.'),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}
