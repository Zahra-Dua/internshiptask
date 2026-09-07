// lib/screens/quick_search_screen.dart
import 'package:flutter/material.dart';
import '../models/component_model.dart';
import '../models/inventory_model.dart';
import '../models/location_model.dart';
import '../services/component_service.dart';
import '../services/inventory_service.dart';
import '../services/location_service.dart';

class QuickSearchScreen extends StatefulWidget {
  const QuickSearchScreen({super.key});

  @override
  State<QuickSearchScreen> createState() => _QuickSearchScreenState();
}

class _QuickSearchScreenState extends State<QuickSearchScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  final _locationService = LocationService();

  String _query = '';

  Color _statusColor(String status) {
    switch (status) {
      case 'OUT_OF_STOCK':
        return Colors.red;
      case 'LOW_STOCK':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OUT_OF_STOCK':
        return 'OUT OF STOCK';
      case 'LOW_STOCK':
        return 'LOW STOCK';
      default:
        return 'IN STOCK';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Quick Search'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type component name or code...',
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
                  setState(() => _query = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Text(
                      'Start typing to find a component instantly',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<List<ComponentModel>>(
                    stream: _componentService.getComponents(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final matches = snapshot.data!
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(_query) ||
                                c.componentCode.toLowerCase().contains(
                                  _query,
                                ) ||
                                c.partNumber.toLowerCase().contains(_query),
                          )
                          .toList();

                      if (matches.isEmpty) {
                        return const Center(child: Text('No matches found'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final component = matches[index];

                          return FutureBuilder<List<InventoryModel>>(
                            future: _inventoryService
                                .getInventoryForComponent(component.id)
                                .first,
                            builder: (context, invSnapshot) {
                              final records = invSnapshot.data ?? [];
                              final totalQty = records.fold<int>(
                                0,
                                (sum, r) => sum + r.quantity,
                              );

                              String status;
                              if (totalQty == 0) {
                                status = 'OUT_OF_STOCK';
                              } else if (totalQty <= component.minimumStock) {
                                status = 'LOW_STOCK';
                              } else {
                                status = 'IN_STOCK';
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _statusColor(
                                      status,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            component.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              status,
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _statusColor(status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      component.componentCode,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total Stock: $totalQty units',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    if (records.isEmpty)
                                      const Text(
                                        'No location recorded',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      )
                                    else
                                      ...records.map(
                                        (r) => FutureBuilder<LocationModel?>(
                                          future: _locationService.getLocation(
                                            r.locationId,
                                          ),
                                          builder: (context, locSnap) {
                                            final loc = locSnap.data;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.place_outlined,
                                                    size: 14,
                                                    color: primaryColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    loc != null
                                                        ? '${loc.locationCode}: ${r.quantity} pcs'
                                                        : 'Loading...',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
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
