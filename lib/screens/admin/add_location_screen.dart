// lib/screens/admin/add_location_screen.dart
import 'package:flutter/material.dart';
import '../../constants/location_constants.dart';
import '../../models/location_model.dart';
import '../../services/location_service.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _suffixController = TextEditingController(); // e.g. "A", "2", "B5"

  String _selectedType = locationTypes.first;
  String? _selectedParentId;
  LocationModel? _selectedParent;
  bool _isLoading = false;
  String? _errorMessage;

  final _locationService = LocationService();
  static const Color primaryColor = Color(0xFF6C63FF);

  String get _previewCode {
    final suffix = _suffixController.text.trim().toUpperCase();
    if (suffix.isEmpty) return '';
    if (_selectedParent == null) return suffix;
    return '${_selectedParent!.locationCode}-$suffix';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = LocationModel(
        id: '',
        name: _nameController.text.trim(),
        type: _selectedType,
        parentId: _selectedParentId,
        locationCode: _previewCode,
        isActive: true,
      );

      await _locationService.addLocation(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location "$_previewCode" added!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'e.g. Rack "A" → Shelf "2" (inside A) → Box "B5" (inside A-2)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: locationTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 12),

              // Parent selector
              StreamBuilder<List<LocationModel>>(
                stream: _locationService.getLocations(),
                builder: (context, snapshot) {
                  final locations = snapshot.data ?? [];

                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedParentId,
                    decoration: const InputDecoration(
                      labelText: 'Parent Location (optional)',
                      helperText: 'Leave empty for a top-level Rack',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Top-level Rack)'),
                      ),
                      ...locations.map(
                        (loc) => DropdownMenuItem<String?>(
                          value: loc.id,
                          child: Text(
                            '${loc.locationCode} — ${loc.name} (${loc.type})',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedParentId = val;
                        _selectedParent = val == null
                            ? null
                            : locations.firstWhere((l) => l.id == val);
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (e.g. "Box 5")',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _suffixController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code Suffix (e.g. "A", "2", "B5")',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  // Agar ye top-level Rack hai, sirf A/B/C/D allow karo
                  if (_selectedParentId == null && _selectedType == 'Rack') {
                    final upper = v.trim().toUpperCase();
                    if (!['A', 'B', 'C', 'D'].contains(upper)) {
                      return 'Top-level Rack must be named A, B, C, or D';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              if (_previewCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Full Code: $_previewCode',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'Add Location',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
