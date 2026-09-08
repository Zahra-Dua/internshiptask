// lib/screens/admin/transfer_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/location_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/cascading_location_picker.dart';

class TransferDialog extends StatefulWidget {
  final ComponentModel component;
  const TransferDialog({super.key, required this.component});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  String? _sourceLocationId;
  String? _destinationLocationId;
  bool _isLoading = false;
  String? _errorMessage;

  final _inventoryService = InventoryService();
  final _locationService = LocationService();
  final _transactionService = TransactionService();
  static const Color primaryColor = Color(0xFF6C63FF);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sourceLocationId == null) {
      setState(() => _errorMessage = 'Please select a source box');
      return;
    }
    if (_destinationLocationId == null) {
      setState(() => _errorMessage = 'Please select a destination box');
      return;
    }
    if (_sourceLocationId == _destinationLocationId) {
      setState(
        () => _errorMessage = 'Source and destination cannot be the same box',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final qty = int.parse(_quantityController.text.trim());

    try {
      await _inventoryService.transferStock(
        componentId: widget.component.id,
        fromLocationId: _sourceLocationId!,
        toLocationId: _destinationLocationId!,
        quantity: qty,
      );

      if (mounted) {
        final currentUser = context.read<AuthProvider>().userModel;
        final sourceLoc = await _locationService.getLocation(
          _sourceLocationId!,
        );
        final destLoc = await _locationService.getLocation(
          _destinationLocationId!,
        );

        await _transactionService.logTransaction(
          TransactionModel(
            id: '',
            componentId: widget.component.id,
            componentName: widget.component.name,
            componentCode: widget.component.componentCode,
            locationId: _sourceLocationId!,
            locationCode: sourceLoc?.locationCode ?? '',
            destinationLocationId: _destinationLocationId,
            destinationLocationCode: destLoc?.locationCode,
            type: TransactionType.transfer,
            quantity: qty,
            userId: currentUser?.id ?? '',
            userName: currentUser?.name ?? 'Unknown',
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(), // 👈 naya
          ),
        );
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
      title: const Text('Transfer Stock'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'From (Source Box)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Source: sirf wahi boxes dikhao jahan is component ka stock hai
              StreamBuilder<List<InventoryModel>>(
                stream: _inventoryService.getInventoryForComponent(
                  widget.component.id,
                ),
                builder: (context, snapshot) {
                  final records = (snapshot.data ?? [])
                      .where((r) => r.quantity > 0)
                      .toList();

                  if (records.isEmpty) {
                    return const Text(
                      'No stock available to transfer.',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    );
                  }

                  return Column(
                    children: records.map((r) {
                      return FutureBuilder<List<LocationModel>>(
                        future: _locationService.getFullPath(r.locationId),
                        builder: (context, pathSnap) {
                          final path = pathSnap.data ?? [];
                          final pathText = path
                              .map((l) => '${l.type} ${l.name}')
                              .join(' → ');
                          return RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: r.locationId,
                            groupValue: _sourceLocationId,
                            title: Text(
                              pathText.isEmpty ? 'Loading...' : pathText,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              'Available: ${r.quantity}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            onChanged: (val) =>
                                setState(() => _sourceLocationId = val),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'To (Destination Box)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Destination: cascading picker, same rack (ABCD class) ke andar
              CascadingLocationPicker(
                rackCode: widget.component.abcdClass,
                onBoxSelected: (boxId) =>
                    setState(() => _destinationLocationId = boxId),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity to transfer',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0)
                    return 'Enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Purpose (optional)',
                  hintText: 'e.g. Reorganizing stock',
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
              : const Text(
                  'Confirm Transfer',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
