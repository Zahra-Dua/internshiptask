// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { issue, returned, restock, damage, transfer }

class TransactionModel {
  final String id;
  final String componentId;
  final String componentName;
  final String componentCode;
  final String locationId;
  final String locationCode;
  final String? destinationLocationId;
  final String? destinationLocationCode;
  final TransactionType type;
  final int quantity;
  final String userId;
  final String userName;
  final String? purpose; // 👈 naya — e.g. "Project XYZ", "Repair"
  final String? notes; // 👈 naya — free-text
  final DateTime? timestamp;

  TransactionModel({
    required this.id,
    required this.componentId,
    required this.componentName,
    required this.componentCode,
    required this.locationId,
    required this.locationCode,
    this.destinationLocationId,
    this.destinationLocationCode,
    required this.type,
    required this.quantity,
    required this.userId,
    required this.userName,
    this.purpose,
    this.notes,
    this.timestamp,
  });

  static TransactionType _typeFromString(String s) {
    switch (s) {
      case 'issue':
        return TransactionType.issue;
      case 'return':
        return TransactionType.returned;
      case 'restock':
        return TransactionType.restock;
      case 'damage':
        return TransactionType.damage;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.issue;
    }
  }

  static String typeToString(TransactionType t) {
    switch (t) {
      case TransactionType.issue:
        return 'issue';
      case TransactionType.returned:
        return 'return';
      case TransactionType.restock:
        return 'restock';
      case TransactionType.damage:
        return 'damage';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TransactionModel(
      id: doc.id,
      componentId: data['componentId'] ?? '',
      componentName: data['componentName'] ?? '',
      componentCode: data['componentCode'] ?? '',
      locationId: data['locationId'] ?? '',
      locationCode: data['locationCode'] ?? '',
      destinationLocationId: data['destinationLocationId'],
      destinationLocationCode: data['destinationLocationCode'],
      type: _typeFromString(data['type'] ?? 'issue'),
      quantity: data['quantity'] ?? 0,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      purpose: data['purpose'],
      notes: data['notes'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'componentId': componentId,
      'componentName': componentName,
      'componentCode': componentCode,
      'locationId': locationId,
      'locationCode': locationCode,
      'destinationLocationId': destinationLocationId,
      'destinationLocationCode': destinationLocationCode,
      'type': typeToString(type),
      'quantity': quantity,
      'userId': userId,
      'userName': userName,
      'purpose': purpose,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
