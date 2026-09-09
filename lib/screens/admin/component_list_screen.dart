// lib/screens/admin/component_list_screen.dart
import 'package:flutter/material.dart';
import 'package:internshiptask/models/audit_log_model.dart';
import 'package:internshiptask/providers/auth_provider.dart';
import 'package:internshiptask/screens/admin/location_list_screen.dart';
import 'package:internshiptask/services/audit_log_service.dart';
import 'package:provider/provider.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/location_model.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import 'add_component_screen.dart';
import 'component_detail_screen.dart';

class ComponentListScreen extends StatefulWidget {
  const ComponentListScreen({super.key});

  @override
  State<ComponentListScreen> createState() => _ComponentListScreenState();
}

class _ComponentListScreenState extends State<ComponentListScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  final _locationService = LocationService();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  Color _classColor(String cls) {
    switch (cls) {
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Sensor':
        return Icons.sensors;
      case 'IC (Integrated Circuit)':
        return Icons.memory;
      case 'Resistor':
      case 'Capacitor':
      case 'Inductor':
      case 'Diode':
      case 'Transistor':
        return Icons.electrical_services;
      case 'Connector':
      case 'Cable/Wire':
        return Icons.cable;
      case 'Switch':
      case 'Relay':
        return Icons.toggle_on_outlined;
      case 'PCB':
        return Icons.developer_board;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            tooltip: 'Manage Locations',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LocationListScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddComponentScreen()));
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, code...',
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

          // Filter chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  [
                    'All',
                    'Sensor',
                    'IC (Integrated Circuit)',
                    'Low Stock',
                    'Resistor',
                    'PCB',
                    'Transistor',
                    'Capacitor',
                    'Diode',
                    'Cable',
                    'Connector',
                  ].map((filter) {
                    final label = filter == 'IC (Integrated Circuit)'
                        ? 'ICs'
                        : filter;
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<ComponentModel>>(
              stream: _componentService.getComponents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var components = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  components = components.where((c) {
                    return c.name.toLowerCase().contains(_searchQuery) ||
                        c.componentCode.toLowerCase().contains(_searchQuery) ||
                        c.partNumber.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (_selectedFilter != 'All' &&
                    _selectedFilter != 'Low Stock') {
                  components = components
                      .where((c) => c.type == _selectedFilter)
                      .toList();
                }

                if (components.isEmpty) {
                  return const Center(child: Text('No components found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: components.length,
                  itemBuilder: (context, index) {
                    final c = components[index];
                    return _ComponentCard(
                      component: c,
                      classColor: _classColor(c.abcdClass),
                      icon: _iconForType(c.type),
                      inventoryService: _inventoryService,
                      locationService: _locationService,
                      lowStockOnly: _selectedFilter == 'Low Stock',
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

// 👇 Top-level function — kahin se bhi (kisi bhi widget se) call ho sakta hai
Future<void> _confirmDeleteComponent(
  BuildContext context,
  ComponentModel component,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Component?'),
      content: Text(
        'Remove "${component.name}" (${component.componentCode})? This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ComponentService().deleteComponent(component.id);
      if (context.mounted) {
        final currentUser = context.read<AuthProvider>().userModel;
        await AuditLogService().logAction(
          AuditLogModel(
            id: '',
            userId: currentUser?.id ?? '',
            userName: currentUser?.name ?? 'Unknown',
            action: AuditAction.delete,
            entityType: 'component',
            entityId: component.id,
            entityLabel: component.name,
          ),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${component.name} deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }
}

// Separate widget so each card can independently fetch its inventory/location data
class _ComponentCard extends StatelessWidget {
  final ComponentModel component;
  final Color classColor;
  final IconData icon;
  final InventoryService inventoryService;
  final LocationService locationService;
  final bool lowStockOnly;

  const _ComponentCard({
    required this.component,
    required this.classColor,
    required this.icon,
    required this.inventoryService,
    required this.locationService,
    required this.lowStockOnly,
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

        // Agar "Low Stock" filter active hai aur ye item low/out nahi hai, to hide karo
        if (lowStockOnly && !isLow && !isOut) {
          return const SizedBox.shrink();
        }

        final statusColor = isOut
            ? Colors.red
            : (isLow ? Colors.orange : Colors.green);
        final statusLabel = isOut
            ? 'OUT OF STOCK'
            : (isLow ? 'LOW STOCK' : 'AVAILABLE');

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComponentDetailScreen(component: component),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: primaryColor, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
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
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: classColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'CLASS ${component.abcdClass}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: classColor,
                                  ),
                                ),
                              ),
                              // 👇 NAYA — Delete menu
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _confirmDeleteComponent(context, component);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            component.type,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '# ${component.componentCode}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location path
                if (records.isNotEmpty)
                  FutureBuilder<List<LocationModel>>(
                    future: locationService.getFullPath(
                      records.first.locationId,
                    ),
                    builder: (context, pathSnap) {
                      final path = pathSnap.data ?? [];
                      final pathText = path
                          .map((l) => '${l.type} ${l.name}')
                          .join(' → ');
                      return Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pathText.isEmpty ? 'Locating...' : pathText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.place_outlined, size: 13, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'No location assigned',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Stock: $totalQty',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.circle, size: 8, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
