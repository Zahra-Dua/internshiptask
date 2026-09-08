// lib/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { issue, returned, restock, damage }

class TransactionModel {
  final String id;
  final String componentId;
  final String componentName; // denormalized — history fast dikhane ke liye
  final String componentCode;
  final String locationId;
  final String locationCode; // denormalized
  final TransactionType type;
  final int quantity;
  final String userId;
  final String userName; // denormalized
  final DateTime? timestamp;

  TransactionModel({
    required this.id,
    required this.componentId,
    required this.componentName,
    required this.componentCode,
    required this.locationId,
    required this.locationCode,
    required this.type,
    required this.quantity,
    required this.userId,
    required this.userName,
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
      type: _typeFromString(data['type'] ?? 'issue'),
      quantity: data['quantity'] ?? 0,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
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
      'type': typeToString(type),
      'quantity': quantity,
      'userId': userId,
      'userName': userName,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
