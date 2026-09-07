import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String userId;
  final String action;
  final String entityType;
  final String entityId;
  final String? description;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final DateTime? createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.description,
    this.previousData,
    this.newData,
    this.createdAt,
  });

  factory AuditLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return AuditLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      description: data['description'],
      previousData: data['previousData'] != null
          ? Map<String, dynamic>.from(data['previousData'])
          : null,
      newData: data['newData'] != null
          ? Map<String, dynamic>.from(data['newData'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'description': description,
      'previousData': previousData,
      'newData': newData,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}