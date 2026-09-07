// lib/models/inventory_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String componentId;
  final String locationId;
  final int quantity;
  final int damagedQuantity;
  final DateTime? updatedAt;

  InventoryModel({
    required this.id,
    required this.componentId,
    required this.locationId,
    required this.quantity,
    required this.damagedQuantity,
    this.updatedAt,
  });

  factory InventoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return InventoryModel(
      id: doc.id,
      componentId: data['componentId'] ?? '',
      locationId: data['locationId'] ?? '',
      quantity: data['quantity'] ?? 0,
      damagedQuantity: data['damagedQuantity'] ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'componentId': componentId,
      'locationId': locationId,
      'quantity': quantity,
      'damagedQuantity': damagedQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  int get usableQuantity => quantity - damagedQuantity;
}
