// lib/models/audit_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction { create, update, delete }

class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final AuditAction action;
  final String entityType; // e.g. "component", "location", "user"
  final String entityId;
  final String entityLabel; // e.g. component name, for display
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime? timestamp;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    this.oldValues,
    this.newValues,
    this.timestamp,
  });

  static AuditAction _actionFromString(String s) {
    switch (s) {
      case 'create':
        return AuditAction.create;
      case 'update':
        return AuditAction.update;
      case 'delete':
        return AuditAction.delete;
      default:
        return AuditAction.update;
    }
  }

  static String actionToString(AuditAction a) {
    switch (a) {
      case AuditAction.create:
        return 'create';
      case AuditAction.update:
        return 'update';
      case AuditAction.delete:
        return 'delete';
    }
  }

  factory AuditLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AuditLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      action: _actionFromString(data['action'] ?? 'update'),
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      entityLabel: data['entityLabel'] ?? '',
      oldValues: data['oldValues'] != null
          ? Map<String, dynamic>.from(data['oldValues'])
          : null,
      newValues: data['newValues'] != null
          ? Map<String, dynamic>.from(data['newValues'])
          : null,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'action': actionToString(action),
      'entityType': entityType,
      'entityId': entityId,
      'entityLabel': entityLabel,
      'oldValues': oldValues,
      'newValues': newValues,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
