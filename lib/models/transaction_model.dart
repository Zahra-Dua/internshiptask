import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String componentId;
  final String userId;
  final String type;
  final int quantity;
  final String locationId;
  final String? destinationLocationId;
  final String? purpose;
  final String? notes;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.componentId,
    required this.userId,
    required this.type,
    required this.quantity,
    required this.locationId,
    this.destinationLocationId,
    this.purpose,
    this.notes,
    this.createdAt,
  });

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return TransactionModel(
      id: doc.id,
      componentId: data['componentId'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      quantity: data['quantity'] ?? 0,
      locationId: data['locationId'] ?? '',
      destinationLocationId: data['destinationLocationId'],
      purpose: data['purpose'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'componentId': componentId,
      'userId': userId,
      'type': type,
      'quantity': quantity,
      'locationId': locationId,
      'destinationLocationId': destinationLocationId,
      'purpose': purpose,
      'notes': notes,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}