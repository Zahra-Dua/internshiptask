// lib/screens/admin/stock_action_dialog.dart
import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../services/inventory_service.dart';
import '../../widgets/cascading_location_picker.dart';

enum StockAction { add, remove, damage }

class StockActionDialog extends StatefulWidget {
  final ComponentModel component;
  final StockAction action;

  const StockActionDialog({
    super.key,
    required this.component,
    required this.action,
  });

  @override
  State<StockActionDialog> createState() => _StockActionDialogState();
}

class _StockActionDialogState extends State<StockActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String? _selectedLocationId;
  bool _isLoading = false;
  String? _errorMessage;

  final _inventoryService = InventoryService();
  static const Color primaryColor = Color(0xFF6C63FF);

  String get _title {
    switch (widget.action) {
      case StockAction.add:
        return 'Add Stock';
      case StockAction.remove:
        return 'Remove Stock';
      case StockAction.damage:
        return 'Mark Damaged';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedLocationId == null) {
      if (_selectedLocationId == null) {
        setState(() => _errorMessage = 'Please select a shelf and box');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final qty = int.parse(_quantityController.text.trim());

    try {
      switch (widget.action) {
        case StockAction.add:
          await _inventoryService.addStock(
            componentId: widget.component.id,
            locationId: _selectedLocationId!,
            quantity: qty,
          );
          break;
        case StockAction.remove:
          await _inventoryService.removeStock(
            componentId: widget.component.id,
            locationId: _selectedLocationId!,
            quantity: qty,
          );
          break;
        case StockAction.damage:
          await _inventoryService.markDamaged(
            componentId: widget.component.id,
            locationId: _selectedLocationId!,
            damagedQty: qty,
          );
          break;
      }

      if (mounted) Navigator.of(context).pop(true);
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CascadingLocationPicker(
                rackCode: widget.component.abcdClass,
                onBoxSelected: (boxId) =>
                    setState(() => _selectedLocationId = boxId),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
