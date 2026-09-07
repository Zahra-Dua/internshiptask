// lib/screens/admin/inventory_overview_screen.dart
import 'package:flutter/material.dart';
import '../../models/inventory_model.dart';
import '../../models/component_model.dart';
import '../../models/location_model.dart';
import '../../services/inventory_service.dart';
import '../../services/component_service.dart';
import '../../services/location_service.dart';

class InventoryOverviewScreen extends StatefulWidget {
  const InventoryOverviewScreen({super.key});

  @override
  State<InventoryOverviewScreen> createState() =>
      _InventoryOverviewScreenState();
}

class _InventoryOverviewScreenState extends State<InventoryOverviewScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _inventoryService = InventoryService();
  final _componentService = ComponentService();
  final _locationService = LocationService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Inventory Overview'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by component name or code',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<InventoryModel>>(
              stream: _inventoryService.getAllInventory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return const Center(child: Text('No inventory records yet.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];

                    return FutureBuilder<List<dynamic>>(
                      future: Future.wait([
                        _componentService.getComponent(record.componentId),
                        _locationService.getLocation(record.locationId),
                      ]),
                      builder: (context, futureSnapshot) {
                        if (!futureSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final component =
                            futureSnapshot.data![0] as ComponentModel?;
                        final location =
                            futureSnapshot.data![1] as LocationModel?;

                        if (component == null) return const SizedBox.shrink();

                        // Search filter
                        if (_searchQuery.isNotEmpty) {
                          final matches =
                              component.name.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              component.componentCode.toLowerCase().contains(
                                _searchQuery,
                              );
                          if (!matches) return const SizedBox.shrink();
                        }

                        final isLowStock =
                            record.quantity <= component.minimumStock;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: isLowStock
                                ? Border.all(
                                    color: Colors.red.withValues(alpha: 0.4),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      component.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      component.componentCode,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.place_outlined,
                                          size: 13,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          location != null
                                              ? '${location.name} (${location.locationCode})'
                                              : 'Unknown',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${record.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isLowStock
                                          ? Colors.red
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (isLowStock)
                                    const Text(
                                      'Low Stock',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red,
                                      ),
                                    ),
                                  if (record.damagedQuantity > 0)
                                    Text(
                                      '${record.damagedQuantity} damaged',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
