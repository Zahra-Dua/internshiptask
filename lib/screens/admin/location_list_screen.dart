// lib/screens/admin/location_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/location_model.dart';
import '../../services/location_service.dart';
import 'add_location_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _locationService = LocationService();

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'rack':
        return Icons.shelves;
      case 'shelf':
        return Icons.view_agenda_outlined;
      case 'box':
        return Icons.inventory_2_outlined;
      case 'drawer':
        return Icons.dns_outlined;
      case 'bin':
        return Icons.delete_outline;
      case 'cabinet':
        return Icons.door_sliding_outlined;
      case 'room':
        return Icons.meeting_room_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Future<void> _confirmDelete(LocationModel location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Location?'),
        content: Text('Remove "${location.name}" (${location.locationCode})?'),
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
        await _locationService.deleteLocation(location.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${location.name} deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    }
  }

  // Ek node aur uske children recursively build karta hai
  Widget _buildLocationNode(LocationModel location, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _iconForType(location.type),
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${location.type} • ${location.locationCode}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!location.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 10, color: Colors.red),
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => _confirmDelete(location),
                ),
              ],
            ),
          ),

          // Children recursively fetch aur render karo
          StreamBuilder<List<LocationModel>>(
            stream: _locationService.getChildLocations(location.id),
            builder: (context, snapshot) {
              final children = snapshot.data ?? [];
              if (children.isEmpty) return const SizedBox.shrink();

              return Column(
                children: children
                    .map((child) => _buildLocationNode(child, depth + 1))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Locations'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text(
          'Add Location',
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => AddLocationScreen()));
        },
      ),
      body: StreamBuilder<List<LocationModel>>(
        stream: _locationService.getRootLocations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rootLocations = snapshot.data ?? [];

          if (rootLocations.isEmpty) {
            return const Center(
              child: Text('No locations yet. Tap "Add Location" to start.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: rootLocations
                .map((loc) => _buildLocationNode(loc, 0))
                .toList(),
          );
        },
      ),
    );
  }
}
