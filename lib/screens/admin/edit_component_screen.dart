// lib/screens/admin/edit_component_screen.dart
import 'package:flutter/material.dart';
import 'package:internshiptask/models/audit_log_model.dart';
import 'package:internshiptask/providers/auth_provider.dart';
import 'package:internshiptask/services/audit_log_service.dart';
import 'package:provider/provider.dart';
import '../../constants/component_constants.dart';
import '../../models/component_model.dart';
import '../../services/component_service.dart';

class EditComponentScreen extends StatefulWidget {
  final ComponentModel component;
  const EditComponentScreen({super.key, required this.component});

  @override
  State<EditComponentScreen> createState() => _EditComponentScreenState();
}

class _EditComponentScreenState extends State<EditComponentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _partNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _minStockController;

  late String _selectedType;
  bool _isLoading = false;
  String? _errorMessage;

  final _componentService = ComponentService();
  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    _nameController = TextEditingController(text: c.name);
    _manufacturerController = TextEditingController(text: c.manufacturer);
    _partNumberController = TextEditingController(text: c.partNumber);
    _descriptionController = TextEditingController(text: c.description);
    _minStockController = TextEditingController(text: '${c.minimumStock}');
    _selectedType = componentTypes.contains(c.type)
        ? c.type
        : componentTypes.first;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _componentService.updateComponent(widget.component.id, {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'manufacturer': _manufacturerController.text.trim(),
        'partNumber': _partNumberController.text.trim(),
        'description': _descriptionController.text.trim(),
        'minimumStock': int.tryParse(_minStockController.text.trim()) ?? 0,
      });
      // _submit() method ke andar, updateComponent call ke baad ye add karo:
      final currentUser = context.read<AuthProvider>().userModel;
      await AuditLogService().logAction(
        AuditLogModel(
          id: '',
          userId: currentUser?.id ?? '',
          userName: currentUser?.name ?? 'Unknown',
          action: AuditAction.update,
          entityType: 'component',
          entityId: widget.component.id,
          entityLabel: widget.component.name,
          oldValues: {
            'name': widget.component.name,
            'minimumStock': widget.component.minimumStock,
          },
          newValues: {
            'name': _nameController.text.trim(),
            'minimumStock': int.tryParse(_minStockController.text.trim()) ?? 0,
          },
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Component updated successfully!')),
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
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Edit Component'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Locked fields — read-only display
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Component Code: ${widget.component.componentCode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ABC Class: ${widget.component.abcdClass} (Rack ${widget.component.abcdClass})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Code and Class cannot be changed after creation. '
                    'If needed, create a new component instead.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Text(
              'Component Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            const Text(
              'Category *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: componentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 14),

            const Text(
              'Manufacturer',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Manufacturer Part Number (MPN)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _partNumberController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Minimum Stock Level *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _minStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 14),

            const Text(
              'Detailed Description',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      icon: const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _submit,
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
