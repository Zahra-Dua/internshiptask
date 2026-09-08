import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/component_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import '../../services/transaction_service.dart';
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

  // Notes controller
  final _notesController = TextEditingController();

  String? _selectedLocationId;
  bool _isLoading = false;
  String? _errorMessage;

  final _inventoryService = InventoryService();
  final _locationService = LocationService();
  final _transactionService = TransactionService();

  static const Color primaryColor = Color(0xFF6C63FF);

  String get _title {
    switch (widget.action) {
      case StockAction.add:
        return 'Add / Return Stock';
      case StockAction.remove:
        return 'Issue Stock';
      case StockAction.damage:
        return 'Mark Damaged';
    }
  }

  TransactionType get _transactionType {
    switch (widget.action) {
      case StockAction.add:
        return TransactionType.restock;
      case StockAction.remove:
        return TransactionType.issue;
      case StockAction.damage:
        return TransactionType.damage;
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

      // Action successful hone ke baad transaction log karo
      if (mounted) {
        final currentUser = context.read<AuthProvider>().userModel;

        final location = await _locationService.getLocation(
          _selectedLocationId!,
        );

        await _transactionService.logTransaction(
          TransactionModel(
            id: '',
            componentId: widget.component.id,
            componentName: widget.component.name,
            componentCode: widget.component.componentCode,
            locationId: _selectedLocationId!,
            locationCode: location?.locationCode ?? '',
            type: _transactionType,
            quantity: qty,
            userId: currentUser?.id ?? '',
            userName: currentUser?.name ?? 'Unknown',

            // Notes / Purpose
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
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
                onBoxSelected: (boxId) {
                  setState(() => _selectedLocationId = boxId);
                },
              ),

              const SizedBox(height: 12),

              // Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Required';
                  }

                  final n = int.tryParse(v);

                  if (n == null || n <= 0) {
                    return 'Enter a valid positive number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Notes / Purpose
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Purpose (optional)',
                  hintText: 'e.g. Project X, repair job',
                ),
                maxLines: 2,
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
