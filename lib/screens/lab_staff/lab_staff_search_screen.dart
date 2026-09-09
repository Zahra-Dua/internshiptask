// lib/screens/lab_staff/lab_staff_search_screen.dart
import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/location_model.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import 'lab_staff_component_detail_screen.dart';

class LabStaffSearchScreen extends StatefulWidget {
  final String initialQuery;
  const LabStaffSearchScreen({super.key, this.initialQuery = ''});

  @override
  State<LabStaffSearchScreen> createState() => _LabStaffSearchScreenState();
}

class _LabStaffSearchScreenState extends State<LabStaffSearchScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  final _locationService = LocationService();

  late TextEditingController _controller;
  String _query = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search components...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['All', 'Sensors', 'ICs', 'Modules', 'Available'].map((
                f,
              ) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const Center(
                    child: Text(
                      'Start typing to search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<List<ComponentModel>>(
                    stream: _componentService.getComponents(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var matches = snapshot.data!.where((c) {
                        return c.name.toLowerCase().contains(_query) ||
                            c.componentCode.toLowerCase().contains(_query) ||
                            c.partNumber.toLowerCase().contains(_query);
                      }).toList();

                      if (_selectedFilter == 'Sensors') {
                        matches = matches
                            .where((c) => c.type == 'Sensor')
                            .toList();
                      } else if (_selectedFilter == 'ICs') {
                        matches = matches
                            .where((c) => c.type == 'IC (Integrated Circuit)')
                            .toList();
                      }

                      if (matches.isEmpty) {
                        return const Center(child: Text('No matches found'));
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '${matches.length} POSSIBLE MATCHES FOUND',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...matches.map(
                            (c) => _MatchCard(
                              component: c,
                              inventoryService: _inventoryService,
                              locationService: _locationService,
                              selectedFilter: _selectedFilter,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final ComponentModel component;
  final InventoryService inventoryService;
  final LocationService locationService;
  final String selectedFilter;

  const _MatchCard({
    required this.component,
    required this.inventoryService,
    required this.locationService,
    required this.selectedFilter,
  });

  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryModel>>(
      stream: inventoryService.getInventoryForComponent(component.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final totalQty = records.fold<int>(0, (sum, r) => sum + r.quantity);
        final isOut = totalQty == 0;
        final isLow = !isOut && totalQty <= component.minimumStock;

        if (selectedFilter == 'Available' && isOut) {
          return const SizedBox.shrink();
        }

        final statusColor = isOut
            ? Colors.red
            : (isLow ? Colors.orange : Colors.green);
        final statusLabel = isOut
            ? 'OUT OF STOCK'
            : (isLow ? 'LOW STOCK' : 'AVAILABLE');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.memory, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          component.type,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity Available',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '$totalQty units',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (records.isNotEmpty)
                FutureBuilder<List<LocationModel>>(
                  future: locationService.getFullPath(records.first.locationId),
                  builder: (context, pathSnap) {
                    final path = pathSnap.data ?? [];
                    final pathText = path
                        .map((l) => '${l.type} ${l.name}')
                        .join(' → ');
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          pathText.isEmpty ? 'Locating...' : pathText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LabStaffComponentDetailScreen(component: component),
                      ),
                    );
                  },
                  child: const Text(
                    'View Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
