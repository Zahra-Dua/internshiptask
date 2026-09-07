// lib/widgets/cascading_location_picker.dart
import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

class CascadingLocationPicker extends StatefulWidget {
  final String rackCode; // Component ki abcdClass — e.g. "A"
  final void Function(String? boxLocationId) onBoxSelected;

  const CascadingLocationPicker({
    super.key,
    required this.rackCode,
    required this.onBoxSelected,
  });

  @override
  State<CascadingLocationPicker> createState() =>
      _CascadingLocationPickerState();
}

class _CascadingLocationPickerState extends State<CascadingLocationPicker> {
  final _locationService = LocationService();

  LocationModel? _rack; // Step 1: Rack — automatic, ABCD class se
  String? _selectedShelfId; // Step 2: Shelf — Admin choose karega
  String? _selectedBoxId; // Step 3: Box — Admin choose karega
  bool _isLoadingRack = true;

  @override
  void initState() {
    super.initState();
    _loadRack();
  }

  // 👇 STEP 1: Component ki class (jaise "A") se uska Rack dhoondo
  Future<void> _loadRack() async {
    final rack = await _locationService.getRackByCode(widget.rackCode);
    setState(() {
      _rack = rack;
      _isLoadingRack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRack) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Agar Rack A/B/C/D create hi nahi hua abhi tak
    if (_rack == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Rack "${widget.rackCode}" doesn\'t exist yet. '
          'Create it first from "Manage Locations".',
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rack — sirf display, choose nahi kar sakte (locked)
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Rack: ${_rack!.name} (${_rack!.locationCode}) — auto-assigned',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 👇 STEP 2: Sirf isi Rack ke andar wali Shelves dikhao
        StreamBuilder<List<LocationModel>>(
          stream: _locationService.getChildLocations(_rack!.id),
          builder: (context, snapshot) {
            final shelves = snapshot.data ?? [];

            if (shelves.isEmpty) {
              return Text(
                'No shelves inside Rack ${_rack!.locationCode} yet. Create one first.',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              );
            }

            return DropdownButtonFormField<String>(
              initialValue: _selectedShelfId,
              decoration: const InputDecoration(labelText: 'Select Shelf'),
              items: shelves
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.locationCode})'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedShelfId = val;
                  _selectedBoxId = null; // shelf badalne pe box reset
                });
                widget.onBoxSelected(null);
              },
            );
          },
        ),
        const SizedBox(height: 12),

        // 👇 STEP 3: Sirf isi Shelf ke andar wali Boxes dikhao (jab tak Shelf select na ho, kuch nahi dikhega)
        if (_selectedShelfId != null)
          StreamBuilder<List<LocationModel>>(
            stream: _locationService.getChildLocations(_selectedShelfId!),
            builder: (context, snapshot) {
              final boxes = snapshot.data ?? [];

              if (boxes.isEmpty) {
                return const Text(
                  'No boxes inside this shelf yet. Create one first.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue: _selectedBoxId,
                decoration: const InputDecoration(labelText: 'Select Box'),
                items: boxes
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.id,
                        child: Text('${b.name} (${b.locationCode})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedBoxId = val);
                  widget.onBoxSelected(
                    val,
                  ); // 👈 sirf yahan final locationId parent ko bheja jata hai
                },
              );
            },
          ),
      ],
    );
  }
}
